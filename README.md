# blinkengraphs for macOS

Menu-bar CPU, memory, disk, network and latency graphs for macOS, with a plain-language Verdict on why the Mac is slow or the network isn't responding.

**Status:** not started. The [Windows version](https://github.com/reconbot/blinkengraphs-win) ships today.

## Scope

- Meters in the menu bar (`NSStatusItem`): CPU, memory pressure, network, disk, latency.
- A Panel with history graphs, latency probes, the hop trace and the top processes.
- Built natively with Swift, SwiftUI and AppKit.
- Distributed outside the Mac App Store, because the App Sandbox blocks the per-process view.

## Spec

The vocabulary, Verdict rules, test vectors and design tokens live in [reconbot/blinkengraphs](https://github.com/reconbot/blinkengraphs). This app implements them natively, and its CI runs the spec's test vectors.

## Repositories

| Repo | Contents |
|---|---|
| [blinkengraphs](https://github.com/reconbot/blinkengraphs) | Landing page and shared spec |
| [blinkengraphs-win](https://github.com/reconbot/blinkengraphs-win) | Windows 11 app (Rust) |
| [blinkengraphs-mac](https://github.com/reconbot/blinkengraphs-mac) | macOS menu bar app (planned) |
| [blinkengraphs-ios](https://github.com/reconbot/blinkengraphs-ios) | iOS network diagnosis app (planned) |
