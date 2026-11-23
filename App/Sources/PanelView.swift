import BlinkengraphsCore
import MacMetrics
import SwiftUI

/// The Panel: the Verdict, then each Section's current value and recent history.
struct PanelView: View {
    let monitor: Monitor
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let tokens = Tokens.forScheme(scheme)
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(monitor.findings.enumerated()), id: \.offset) { _, finding in
                    Label(finding.headline, systemImage: finding.severity == .ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(tokens.ui(finding.severity.token))
                        .font(.headline)
                }
            }
            Divider()
            ForEach(Monitor.Section.allCases) { section in
                HStack {
                    Text(section.rawValue).frame(width: 64, alignment: .leading)
                    Sparkline(values: monitor.history[section, default: []], color: tokens.ui(section.token))
                        .frame(height: 24)
                    Text(readout(section)).monospacedDigit().frame(width: 110, alignment: .trailing)
                }
            }
            Divider()
            HStack {
                Text(monitor.followedAdapter.map { "Following \($0)" } ?? "No network").foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .font(.caption)
        }
        .padding(14)
        .frame(width: 380)
    }

    private func readout(_ section: Monitor.Section) -> String {
        guard let r = monitor.reading else { return "–" }
        let s = r.sample
        switch section {
        case .cpu: return s.cpuBusy.map { "\(Int($0.rounded()))%" } ?? "–"
        case .memory:
            let used = r.memoryUsed.map { "\(Int(($0 * 100).rounded()))%" } ?? "–"
            return s.memPressure.map { "\(used) · \($0.rawValue)" } ?? used
        case .disk:
            guard let worst = s.disks.max(by: { $0.busy < $1.busy }) else { return "–" }
            return "\(Int(worst.busy.rounded()))% · \(Int(worst.responseMs.rounded())) ms"
        case .network:
            return "↓\(rate(s.netDown)) ↑\(rate(s.netUp))"
        }
    }

    private func rate(_ bps: Double?) -> String {
        guard let b = bps else { return "–" }
        return Int64(b).formatted(.byteCount(style: .decimal)) + "/s"
    }
}

private struct Sparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let step = geo.size.width / Double(Monitor.historyLength - 1)
            Path { p in
                for (i, v) in values.enumerated() {
                    let pt = CGPoint(x: geo.size.width - Double(values.count - 1 - i) * step,
                                     y: geo.size.height * (1 - min(max(v, 0), 1)))
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
            }
            .stroke(color, lineWidth: 1.5)
        }
        .background(color.opacity(0.1), in: .rect(cornerRadius: 3))
    }
}
