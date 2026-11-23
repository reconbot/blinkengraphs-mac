import BlinkengraphsCore
import Testing
@testable import MacMetrics

private func counters(at: Double, _ edit: (inout Counters) -> Void = { _ in }) -> Counters {
    var c = Counters(at: at, pageSize: 16384, physicalBytes: 16 << 30)
    edit(&c)
    return c
}

@Test func cpuBusyIsTheNonIdleShareOfTicks() {
    let a = counters(at: 0) { $0.cpu = .init(user: 100, system: 50, idle: 800, nice: 50) }
    let b = counters(at: 1) { $0.cpu = .init(user: 160, system: 80, idle: 900, nice: 60) }
    // busy Δ 60+30+10 = 100 of 200
    #expect(Rates.reading(from: a, to: b, followed: nil).sample.cpuBusy == 50)
}

@Test func cpuTicksWrapAt32Bits() {
    let a = counters(at: 0) { $0.cpu = .init(user: .max - 9, system: 0, idle: 0, nice: 0) }
    let b = counters(at: 1) { $0.cpu = .init(user: 10, system: 0, idle: 20, nice: 0) }
    #expect(Rates.reading(from: a, to: b, followed: nil).sample.cpuBusy == 50)
}

@Test func pageInsAreBytesPerSecondAtThePageSize() {
    let a = counters(at: 10) { $0.pageIns = 1_000 }
    let b = counters(at: 12) { $0.pageIns = 1_500 }
    // 500 pages × 16 KiB over 2 s
    #expect(Rates.reading(from: a, to: b, followed: nil).sample.memPageIns == 4_096_000)
}

@Test func diskBusyIsCappedAndResponseIsTimePerRequest() {
    let a = counters(at: 0) { $0.disks = [7: .init(operations: 100, totalTimeNs: 0)] }
    // 3 s of request time in 1 s: three requests in flight on average.
    let b = counters(at: 1) { $0.disks = [7: .init(operations: 160, totalTimeNs: 3_000_000_000)] }
    let disk = Rates.reading(from: a, to: b, followed: nil).sample.disks
    #expect(disk == [Sample.Disk(busy: 100, responseMs: 50)])
}

@Test func aDiskMissingFromEitherReadDropsOut() {
    let a = counters(at: 0) { $0.disks = [1: .init(operations: 0, totalTimeNs: 0)] }
    let b = counters(at: 1) { $0.disks = [2: .init(operations: 5, totalTimeNs: 5)] }
    #expect(Rates.reading(from: a, to: b, followed: nil).sample.disks.isEmpty)
}

@Test func networkReadsOnlyTheFollowedAdapterAndWraps() {
    let a = counters(at: 0) { $0.interfaces = ["en0": .init(bytesIn: .max - 999, bytesOut: 0), "en1": .init(bytesIn: 0, bytesOut: 0)] }
    let b = counters(at: 1) { $0.interfaces = ["en0": .init(bytesIn: 1_000, bytesOut: 500), "en1": .init(bytesIn: 9, bytesOut: 9)] }
    let s = Rates.reading(from: a, to: b, followed: "en0").sample
    #expect(s.netDown == 2_000)
    #expect(s.netUp == 500)
    #expect(Rates.reading(from: a, to: b, followed: nil).sample.netUp == nil)
}

@Test func pressureLevelsMapFromTheKernelsValues() {
    #expect(Rates.pressure(level: 1) == .normal)
    #expect(Rates.pressure(level: 2) == .warn)
    #expect(Rates.pressure(level: 4) == .critical)
    #expect(Rates.pressure(level: 0) == nil)
}

@Test func memoryUsedIsAShareOfPhysicalMemory() {
    let b = counters(at: 1) { $0.usedPages = 524_288 } // 8 GiB of 16 KiB pages
    #expect(Rates.reading(from: counters(at: 0), to: b, followed: nil).memoryUsed == 0.5)
}

@Test func theLocalRulesFireFromAReading() {
    let a = counters(at: 0) { $0.cpu = .init(user: 0, system: 0, idle: 0, nice: 0); $0.pageIns = 0 }
    let b = counters(at: 1) {
        $0.cpu = .init(user: 95, system: 0, idle: 5, nice: 0)
        $0.pageIns = 400 // 6.6 MB/s
        $0.pressure = .warn
    }
    let findings = Verdict.evaluate(VerdictInput(probes: [], sample: Rates.reading(from: a, to: b, followed: nil).sample))
    #expect(findings.map(\.headline) == ["CPU pinned at 95%", "Paging heavily: 6.6 MB/s from disk"])
}
