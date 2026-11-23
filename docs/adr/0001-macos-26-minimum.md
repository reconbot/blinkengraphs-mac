# macOS 26 is the minimum

**Status:** accepted

The app targets macOS 26 Tahoe and later. It uses Swift 6 and the newest SwiftUI and AppKit with no availability checks; the owner chose reach on current Macs over older ones.

## Considered options

- **macOS 15 Sequoia**, the floor blinkengraphs-kit declares. Rejected by the owner: a smaller audience gain than the cost of availability branches.
- **macOS 14 Sonoma.** Rejected: it would lower the kit's platform floor too.

## Consequences

- CI builds on the `macos-26` runner.
- `MacMetrics` declares `.macOS(.v26)`, which needs swift-tools 6.2.
