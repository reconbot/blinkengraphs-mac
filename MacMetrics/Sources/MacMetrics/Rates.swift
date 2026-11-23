import BlinkengraphsCore
import Foundation

/// Turns two `Counters` into the spec's Metrics (spec rules/verdict.md, "Local rules").
public enum Rates {
    public static func reading(from a: Counters, to b: Counters, followed: String?) -> Reading {
        let dt = b.at - a.at
        guard dt > 0 else { return Reading(sample: Sample(memPressure: b.pressure), memoryUsed: memoryUsed(b)) }
        var s = Sample(memPressure: b.pressure)

        if let x = a.cpu, let y = b.cpu {
            let busy = Double(y.user &- x.user) + Double(y.system &- x.system) + Double(y.nice &- x.nice)
            let all = busy + Double(y.idle &- x.idle)
            if all > 0 { s.cpuBusy = busy / all * 100 }
        }
        if let x = a.pageIns, let y = b.pageIns {
            s.memPageIns = Double(rise(x, y) * b.pageSize) / dt
        }
        s.disks = b.disks.keys.sorted().compactMap { id in
            guard let x = a.disks[id], let y = b.disks[id] else { return nil }
            let timeNs = Double(rise(x.totalTimeNs, y.totalTimeNs))
            let ops = Double(rise(x.operations, y.operations))
            // macOS counts time per request, so concurrent requests overlap: this is the mean number
            // in flight, capped at 100% as the spec allows (docs/adr/0004-local-metrics.md).
            let busy = min(timeNs / (dt * 1e9) * 100, 100)
            return Sample.Disk(busy: busy, responseMs: ops > 0 ? timeNs / ops / 1e6 : 0)
        }
        if let name = followed, let x = a.interfaces[name], let y = b.interfaces[name] {
            s.netDown = Double(y.bytesIn &- x.bytesIn) / dt
            s.netUp = Double(y.bytesOut &- x.bytesOut) / dt
        }
        return Reading(sample: s, memoryUsed: memoryUsed(b))
    }

    /// Kernel 64-bit counters only reset on reboot; a drop reads as no change.
    private static func rise(_ x: UInt64, _ y: UInt64) -> UInt64 { y >= x ? y - x : 0 }

    private static func memoryUsed(_ c: Counters) -> Double? {
        guard let used = c.usedPages, c.physicalBytes > 0 else { return nil }
        return min(Double(used * c.pageSize) / Double(c.physicalBytes), 1)
    }

    /// `kern.memorystatus_vm_pressure_level`: 1 normal, 2 warn, 4 critical (xnu bsd/sys/event_private.h).
    public static func pressure(level: Int32) -> Sample.MemPressure? {
        switch level {
        case 1: .normal
        case 2: .warn
        case 4: .critical
        default: nil
        }
    }
}
