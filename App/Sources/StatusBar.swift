import AppKit
import BlinkengraphsCore
import SwiftUI

/// One menu-bar item holding every Section's Meter side by side; a click opens the Panel.
@MainActor
final class StatusBar: NSObject {
    private static let columns = 11, columnWidth = 2.0, height = 16.0, gap = 4.0

    private let monitor: Monitor
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    init(monitor: Monitor) {
        self.monitor = monitor
        super.init()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PanelView(monitor: monitor))
        item.button?.target = self
        item.button?.action = #selector(toggle)
        item.button?.setAccessibilityLabel("blinkengraphs")
        redraw()
        observe()
    }

    @objc private func toggle() {
        guard let button = item.button else { return }
        if popover.isShown { popover.performClose(nil) } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func observe() {
        withObservationTracking { _ = monitor.history } onChange: { [weak self] in
            Task { @MainActor in self?.redraw(); self?.observe() }
        }
    }

    private func redraw() {
        let dark = item.button?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let tokens = dark ? SpecResources.tokens : SpecResources.lightTokens
        let sections = Monitor.Section.allCases
        let meterWidth = Double(Self.columns) * Self.columnWidth
        let size = NSSize(width: Double(sections.count) * meterWidth + Double(sections.count - 1) * Self.gap, height: Self.height)
        let history = monitor.history
        item.button?.image = NSImage(size: size, flipped: false) { _ in
            for (i, section) in sections.enumerated() {
                let x0 = Double(i) * (meterWidth + Self.gap)
                tokens.ns(section.token).withAlphaComponent(0.18).setFill()
                NSRect(x: x0, y: 0, width: meterWidth, height: Self.height).fill()
                tokens.ns(section.token).setFill()
                // Newest at the right edge.
                for (j, value) in history[section, default: []].suffix(Self.columns).reversed().enumerated() {
                    let h = max(1, min(value, 1) * Self.height)
                    NSRect(x: x0 + meterWidth - Double(j + 1) * Self.columnWidth, y: 0, width: Self.columnWidth, height: h).fill()
                }
            }
            return true
        }
        item.button?.toolTip = monitor.findings.first?.headline
    }
}
