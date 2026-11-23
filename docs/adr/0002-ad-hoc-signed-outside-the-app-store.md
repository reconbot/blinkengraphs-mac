# Ad-hoc signed, outside the App Store

**Status:** accepted

The App Sandbox blocks the per-process view and some system counters, so the app ships outside the Mac App Store, unsandboxed. Until a Developer ID certificate exists it is **ad-hoc signed** (`CODE_SIGN_IDENTITY = -`): Apple silicon runs no unsigned native code ([Apple: macOS Big Sur 11.0.1 universal apps release notes](https://developer.apple.com/documentation/macos-release-notes/macos-big-sur-11_0_1-universal-apps-release-notes)), and an ad-hoc signature needs no Apple account.

- CI uploads the app as a zip on every run; each release carries one.
- Gatekeeper blocks an un-notarized download. Since macOS 15 the Control-click Open bypass is gone; the user allows it in System Settings › Privacy & Security, or runs `xattr -dr com.apple.quarantine Blinkengraphs.app` ([Apple Developer news, August 2024](https://developer.apple.com/news/?id=saqachfa)).

## Considered options

- **Developer ID signing and notarization now.** Deferred by the owner: it needs a paid account and CI secrets.
- **App Store.** Rejected: the sandbox removes the Process Snapshot.

## Consequences

- Moving to Developer ID means the hardened runtime, a signing identity and notarization in `release.yml`; the bundle ID prefix must then be one the owner holds.
