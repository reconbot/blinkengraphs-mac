import BlinkengraphsCore
import Foundation
import MacMetrics
import Network
import Observation

/// Reads the local Metrics every `system_interval_ms`, keeps a short history per Section for the
/// Meters, and evaluates the Verdict. Probes come later; until then only the Local rules can fire.
@MainActor @Observable
final class Monitor {
    enum Section: String, CaseIterable, Identifiable {
        case cpu = "CPU", memory = "Memory", disk = "Disk", network = "Network"
        var id: Self { self }
        var token: String { "color.section.\(rawValue.lowercased())" }
    }

    static let historyLength = 30

    private(set) var reading: Reading?
    private(set) var findings: [Finding] = [Finding(domain: .clear, severity: .ok, headline: "All clear")]
    /// 0–1 per Section, oldest first, at most `historyLength`.
    private(set) var history: [Section: [Double]] = [:]
    private(set) var followedAdapter: String?

    private let counters = SystemCounters()
    @ObservationIgnored private var last: Counters?
    @ObservationIgnored private var timer: Timer?
    private let path = NWPathMonitor()
    /// The busiest network rates seen: the Network Meter's full height and the Verdict's upload_peak_bps.
    @ObservationIgnored private var peakDown = 0.0
    @ObservationIgnored private var peakUp = 0.0

    func start() {
        // The Followed Adapter is the one carrying the default route; the OS lists it first.
        path.pathUpdateHandler = { [weak self] update in
            let name = update.availableInterfaces.first?.name
            Task { @MainActor in self?.followedAdapter = name }
        }
        path.start(queue: .main)
        last = counters.read()
        let interval = Double(SpecResources.systemIntervalMs) / 1000
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        let now = counters.read()
        guard let previous = last else { last = now; return }
        last = now
        let r = Rates.reading(from: previous, to: now, followed: followedAdapter)
        reading = r
        let s = r.sample
        peakDown = max(peakDown, s.netDown ?? 0)
        peakUp = max(peakUp, s.netUp ?? 0)
        push(.cpu, (s.cpuBusy ?? 0) / 100)
        push(.memory, r.memoryUsed ?? 0)
        push(.disk, (s.disks.map(\.busy).max() ?? 0) / 100)
        push(.network, Meter.cubeRoot((s.netDown ?? 0) + (s.netUp ?? 0), max: peakDown + peakUp))
        findings = Verdict.evaluate(VerdictInput(probes: [], sample: s, uploadPeakBps: peakUp))
    }

    private func push(_ section: Section, _ value: Double) {
        var h = history[section, default: []]
        h.append(value)
        if h.count > Self.historyLength { h.removeFirst(h.count - Self.historyLength) }
        history[section] = h
    }
}
