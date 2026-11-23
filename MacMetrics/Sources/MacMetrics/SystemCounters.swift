import BlinkengraphsCore
import Darwin
import Foundation
import IOKit

/// Reads `Counters` from the kernel. Every call here works unprivileged and unsandboxed
/// (spec docs/local-metrics.md cites the source for each).
public struct SystemCounters: Sendable {
    // mach_host_self() returns a new send right each call; take one for the process.
    private let host: mach_port_t
    private let pageSize: UInt64
    private let physicalBytes: UInt64

    public init() {
        host = mach_host_self()
        // hw.pagesize rather than vm_page_size: Swift 6 rejects that C global as shared mutable state.
        pageSize = UInt64(Self.sysctlInt64("hw.pagesize") ?? 16384)
        physicalBytes = ProcessInfo.processInfo.physicalMemory
    }

    public func read() -> Counters {
        let vm = vmStatistics()
        return Counters(
            at: ProcessInfo.processInfo.systemUptime,
            cpu: cpuTicks(),
            pageIns: vm.map { $0.pageins + $0.swapins },
            pageSize: pageSize,
            usedPages: vm.map { UInt64($0.internal_page_count) + UInt64($0.wire_count) + UInt64($0.compressor_page_count) },
            physicalBytes: physicalBytes,
            pressure: Self.sysctlInt32("kern.memorystatus_vm_pressure_level").flatMap(Rates.pressure(level:)),
            disks: Self.disks(),
            interfaces: Self.interfaces()
        )
    }

    // host_statistics(HOST_CPU_LOAD_INFO): ticks summed over every logical CPU (xnu osfmk/kern/host.c).
    private func cpuTicks() -> Counters.CPU? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count) }
        }
        guard kr == KERN_SUCCESS else { return nil }
        let t = info.cpu_ticks // CPU_STATE_USER, SYSTEM, IDLE, NICE
        return Counters.CPU(user: t.0, system: t.1, idle: t.2, nice: t.3)
    }

    private func vmStatistics() -> vm_statistics64? {
        var vm = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &vm) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(host, HOST_VM_INFO64, $0, &count) }
        }
        return kr == KERN_SUCCESS ? vm : nil
    }

    // IOBlockStorageDriver "Statistics". Use Total Time, not Latency Time: the base driver leaves the
    // latency keys at 0 (IOStorageFamily IOBlockStorageDriver.cpp).
    private static func disks() -> [UInt64: Counters.Disk] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) == KERN_SUCCESS
        else { return [:] }
        defer { IOObjectRelease(iterator) }
        var out: [UInt64: Counters.Disk] = [:]
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            var id: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(entry, &id)
            if let stats = IORegistryEntryCreateCFProperty(entry, "Statistics" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? [String: Any] {
                func value(_ key: String) -> UInt64 { (stats[key] as? NSNumber)?.uint64Value ?? 0 }
                out[id] = Counters.Disk(operations: value("Operations (Read)") + value("Operations (Write)"),
                                        totalTimeNs: value("Total Time (Read)") + value("Total Time (Write)"))
            }
        }
        return out
    }

    private static func interfaces() -> [String: Counters.Interface] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0 else { return [:] }
        defer { freeifaddrs(head) }
        var out: [String: Counters.Interface] = [:]
        var cursor = head
        while let ifa = cursor?.pointee {
            if ifa.ifa_addr?.pointee.sa_family == UInt8(AF_LINK), let raw = ifa.ifa_data {
                let data = raw.assumingMemoryBound(to: if_data.self).pointee
                out[String(cString: ifa.ifa_name)] = Counters.Interface(bytesIn: data.ifi_ibytes, bytesOut: data.ifi_obytes)
            }
            cursor = ifa.ifa_next
        }
        return out
    }

    private static func sysctlInt32(_ name: String) -> Int32? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? value : nil
    }

    private static func sysctlInt64(_ name: String) -> Int64? {
        var value: Int64 = 0
        var size = MemoryLayout<Int64>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? value : nil
    }
}
