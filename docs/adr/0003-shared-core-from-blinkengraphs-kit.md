# The shared core comes from blinkengraphs-kit; the spec is a submodule

**Status:** accepted

The Verdict, Probe stats, Hop Trace, History and Defaults come from [blinkengraphs-kit](https://github.com/reconbot/blinkengraphs-kit)'s `BlinkengraphsCore`, the package the iOS app also uses ([kit ADR 0001](https://github.com/reconbot/blinkengraphs-kit/blob/main/docs/adr/0001-one-package-shared-by-the-apple-apps.md)). macOS code lives here: `MacMetrics` reads the kernel's counters, the app draws Meters and the Panel.

- `project.yml` and `MacMetrics/Package.swift` pin one exact kit version. `scripts/kit-vectors.sh` fails when they differ.
- The spec is the `spec/` submodule on a release tag. The app bundles its defaults and tokens.
- CI runs the kit's tests at the pinned version against this repo's spec pin (`scripts/kit-vectors.sh`), so the app ships a core that passes the vectors of the spec it bundles.

## Consequences

- A spec release reaches the app as a kit release, then a PR here bumping the kit version and `spec/` together.
