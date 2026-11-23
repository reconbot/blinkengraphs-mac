# blinkengraphs for macOS

Menu-bar CPU, memory, disk, network and latency graphs for macOS, with a plain-language Verdict on why the Mac is slow or the network isn't responding.

**Status:** early. The menu bar shows CPU, memory, disk and network Meters, and the Panel gives the Verdict on local load. Latency Probes, the Hop Trace and the Process Snapshot come next. Needs macOS 26 or later. The [Windows](https://github.com/reconbot/blinkengraphs-win) and [iOS](https://github.com/reconbot/blinkengraphs-ios) versions ship today.

## Install

Each CI run and release carries `blinkengraphs-mac.zip`, an ad-hoc-signed app that is not notarized ([ADR 0002](docs/adr/0002-ad-hoc-signed-outside-the-app-store.md)). Unzip it into Applications, then allow it once: System Settings › Privacy & Security › Open Anyway, or `xattr -dr com.apple.quarantine /Applications/Blinkengraphs.app`.

## Build

```sh
git submodule update --init
brew install xcodegen && xcodegen generate
open Blinkengraphs.xcodeproj
swift test --package-path MacMetrics    # counter-to-Metric math
scripts/kit-vectors.sh                  # the shared core against this app's spec pin
```

## Scope

- Meters in the menu bar (`NSStatusItem`): CPU, memory pressure, network, disk, latency.
- A Panel with history graphs, latency probes, the hop trace and the top processes.
- Built natively with Swift, SwiftUI and AppKit.
- Distributed outside the Mac App Store, because the App Sandbox blocks the per-process view.

## Spec

The vocabulary, Verdict rules, test vectors and design tokens live in [reconbot/blinkengraphs](https://github.com/reconbot/blinkengraphs). The rules code is shared with iOS through [blinkengraphs-kit](https://github.com/reconbot/blinkengraphs-kit), and this app's CI runs the spec's vectors against it.

## Repositories

| Repo | Contents |
|---|---|
| [blinkengraphs](https://github.com/reconbot/blinkengraphs) | Landing page and shared spec |
| [blinkengraphs-win](https://github.com/reconbot/blinkengraphs-win) | Windows 11 app (Rust) |
| [blinkengraphs-mac](https://github.com/reconbot/blinkengraphs-mac) | macOS menu bar app |
| [blinkengraphs-ios](https://github.com/reconbot/blinkengraphs-ios) | iOS network diagnosis app |
| [blinkengraphs-kit](https://github.com/reconbot/blinkengraphs-kit) | Swift package shared by the iOS and macOS apps |
