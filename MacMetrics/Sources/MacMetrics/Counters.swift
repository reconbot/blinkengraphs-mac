import BlinkengraphsCore
import Foundation

/// Cumulative counters read at one instant. Rates come from two of them (`Rates`).
public struct Counters: Sendable, Equatable {
    public struct CPU: Sendable, Equatable {
        // natural_t ticks: 32-bit, so they wrap; deltas use wrapping subtraction.
        public var user: UInt32, system: UInt32, idle: UInt32, nice: UInt32
        public init(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) {
            self.user = user; self.system = system; self.idle = idle; self.nice = nice
        }
    }

    public struct Disk: Sendable, Equatable {
        public var operations: UInt64
        /// Nanoseconds spent on completed requests, reads plus writes.
        public var totalTimeNs: UInt64
        public init(operations: UInt64, totalTimeNs: UInt64) { self.operations = operations; self.totalTimeNs = totalTimeNs }
    }

    public struct Interface: Sendable, Equatable {
        // if_data's byte counters are 32-bit: they wrap every 4 GB.
        public var bytesIn: UInt32, bytesOut: UInt32
        public init(bytesIn: UInt32, bytesOut: UInt32) { self.bytesIn = bytesIn; self.bytesOut = bytesOut }
    }

    /// Monotonic seconds.
    public var at: Double
    public var cpu: CPU?
    /// Pages read from disk into memory, file-backed plus swap.
    public var pageIns: UInt64?
    public var pageSize: UInt64
    /// Pages in use: app (internal), wired and compressed.
    public var usedPages: UInt64?
    public var physicalBytes: UInt64
    public var pressure: Sample.MemPressure?
    /// Keyed by IORegistry entry ID, so a disk unplugged between reads drops out.
    public var disks: [UInt64: Disk]
    public var interfaces: [String: Interface]

    public init(at: Double, cpu: CPU? = nil, pageIns: UInt64? = nil, pageSize: UInt64 = 16384,
                usedPages: UInt64? = nil, physicalBytes: UInt64 = 0, pressure: Sample.MemPressure? = nil,
                disks: [UInt64: Disk] = [:], interfaces: [String: Interface] = [:]) {
        self.at = at; self.cpu = cpu; self.pageIns = pageIns; self.pageSize = pageSize
        self.usedPages = usedPages; self.physicalBytes = physicalBytes; self.pressure = pressure
        self.disks = disks; self.interfaces = interfaces
    }
}

/// One instant's readings for the Meters and the Verdict.
public struct Reading: Sendable, Equatable {
    public var sample: Sample
    /// Share of physical memory in use, 0–1. Shown by the Memory Meter; the Verdict reads pressure.
    public var memoryUsed: Double?
}
