# blinkengraphs for macOS

Native Swift, SwiftUI and AppKit menu-bar app. Scope is in `README.md`.

The spec repo, reconbot/blinkengraphs, is the authority, except where an ADR here records a departure. Pin a release tag, and run its vectors in CI:
- `CONTEXT.md`: vocabulary. Use its terms in code and UI.
- `rules/`: Verdict, Probe stats, Hop Trace.
- `vectors/`: conformance tests. An implementation conforms when every vector passes.
- `defaults.json`: Probe Group, intervals, timeouts, history lengths.
- `tokens/`, `fixtures/`: colors and thresholds; data for previews and screenshots.

Changes that touch more than one repo follow the spec's `docs/sync.md`: when the spec releases, bump the kit version and `spec/` together in one PR.

A rule this app needs but the spec lacks is a spec PR first, unless it is a departure for this app's normal use ([spec ADR 0002](https://github.com/reconbot/blinkengraphs/blob/main/docs/adr/0002-platforms-may-depart-for-their-normal-use.md)): then it is an ADR here naming the rule it replaces, and CI skips any vector it voids, by name.

The rules code is reconbot/blinkengraphs-kit's `BlinkengraphsCore`; a change to it is a kit PR. This repo holds macOS code only: `MacMetrics/` reads kernel counters into the spec's Local Metrics (ADR 0004), `App/` draws the Meters and the Panel. `project.yml` (XcodeGen; `xcodegen generate`) and `MacMetrics/Package.swift` pin the same kit version; `scripts/kit-vectors.sh` runs the kit's tests against `spec/`.

macOS Local Network Privacy can block Gateway Probes: report them as `denied`, never as loss.

Project memory lives in the repo: decisions `docs/adr/`, research `docs/research/`. Record learnings there.

Skills come from `.claude/settings.json` (`mattpocock-skills`): `domain-modeling` when a term or decision changes, `codebase-design` when shaping a module interface, `tdd` for features and fixes, `writing-for-agents` for any doc or CLAUDE.md edit.

Comments carry only what code can't: the why, the platform gotcha, the source URL. Prose earns each sentence.

Commits follow Conventional Commits. Commits, PRs and comments stay free of session links and personal or employer details; the repo is public.

Never force-push `main` once the repo has a release.

Release PRs (release-please) merge only after the owner has reviewed them and said so. Feature PRs merge when tests pass.
