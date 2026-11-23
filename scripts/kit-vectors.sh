#!/usr/bin/env bash
# Runs blinkengraphs-kit's tests, at the version project.yml pins, against this repo's spec pin,
# so the shared core passes the vectors of the spec this app ships (kit docs/adr/0001).
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(awk '/BlinkengraphsKit:/ { f = 1 } f && /exactVersion:/ { print $2; exit }' project.yml)
[[ -n "$version" ]] || { echo "no BlinkengraphsKit exactVersion in project.yml" >&2; exit 1; }
grep -q "exact: \"$version\"" MacMetrics/Package.swift \
  || { echo "MacMetrics/Package.swift does not pin blinkengraphs-kit $version" >&2; exit 1; }
dir=$(mktemp -d)
git clone --quiet --depth 1 --branch "v$version" https://github.com/reconbot/blinkengraphs-kit.git "$dir"
BLINKENGRAPHS_SPEC="$PWD/spec" swift test --package-path "$dir"
