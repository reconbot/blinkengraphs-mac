import BlinkengraphsCore
import Foundation

enum SpecResources {
    static let defaults: Defaults = load("defaults") { shared in
        try Defaults.decode(shared, override: data("defaults.override"))
    }
    static let tokens: Tokens = load("blinkengraphs.tokens", Tokens.decode)
    /// The light appearance's colors at the same paths (spec tokens/README.md).
    static let lightTokens: Tokens = load("blinkengraphs.light.tokens", Tokens.decode)
    /// The pinned spec's release, from release-please's manifest.
    /// Soft-fails to "unknown": Xcode may skip dot-files when copying resources.
    static let specVersion: String = Bundle.main.url(forResource: ".release-please-manifest", withExtension: "json")
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }?["."] ?? "unknown"

    /// `system_interval_ms`, which the shared Defaults type leaves out because iOS has no local Metrics.
    static let systemIntervalMs: Int = {
        let merged = DefaultsMerge.merge(json(data("defaults")), json(data("defaults.override"))) as? [String: Any]
        return (merged?["system_interval_ms"] as? NSNumber)?.intValue ?? 1000
    }()

    private static func json(_ data: Data) -> Any { (try? JSONSerialization.jsonObject(with: data)) ?? [String: Any]() }

    private static func load<T>(_ name: String, _ decode: (Data) throws -> T) -> T {
        guard let value = try? decode(data(name)) else { fatalError("\(name).json missing or invalid") }
        return value
    }

    private static func data(_ name: String) -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { fatalError("\(name).json missing from the bundle; run `git submodule update --init`") }
        return data
    }
}
