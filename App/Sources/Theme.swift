import AppKit
import BlinkengraphsCore
import SwiftUI

extension RGB {
    var nsColor: NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }
    var color: Color { Color(nsColor) }
}

extension Tokens {
    /// The token, or gray when the pinned spec lacks it, so a renamed token shows instead of crashing.
    func ns(_ path: String) -> NSColor { color(path)?.nsColor ?? .systemGray }
    func ui(_ path: String) -> Color { Color(ns(path)) }

    static func forScheme(_ scheme: ColorScheme) -> Tokens {
        scheme == .dark ? SpecResources.tokens : SpecResources.lightTokens
    }
}

extension Severity {
    var token: String {
        switch self {
        case .crit: "color.severity.crit"
        case .warn: "color.severity.warn"
        case .ok: "color.severity.ok"
        }
    }
}
