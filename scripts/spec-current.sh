#!/usr/bin/env bash
# Warns when the pinned spec is older than the spec's latest release, or is not on a release
# tag at all (CLAUDE.md: pin a tagged version; bump it whenever the spec releases). Never fails
# the build: the warning shows on the run and its pull request.
set -euo pipefail

repo=https://github.com/reconbot/blinkengraphs.git
pinned=$(git rev-parse "${1:-HEAD}:spec")

# Each tag's commit; an annotated tag's peeled line (^{}) wins over the tag object's.
tags=$(git ls-remote --tags "$repo" 'v*' | awk '{ ref = $2; sub("refs/tags/", "", ref);
  if (ref ~ /\^\{\}$/) { sub(/\^\{\}$/, "", ref); peeled[ref] = $1 } else plain[ref] = $1 }
  END { for (r in plain) print (r in peeled ? peeled[r] : plain[r]), r }')
latest=$(printf '%s\n' "$tags" | sort -k2,2V | tail -1)
latest_sha=${latest%% *} latest_tag=${latest##* }
pinned_tag=$(printf '%s\n' "$tags" | awk -v sha="$pinned" '$1 == sha { print $2 }' | sort -V | tail -1)

say() { echo "::warning title=Spec is behind::$1"; echo "⚠️ $1" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; }
if [[ -z "$latest_tag" ]]; then
  echo "::warning title=Spec check::could not list the spec's tags"
elif [[ -z "$pinned_tag" ]]; then
  say "spec is pinned to ${pinned:0:7}, not a release tag; the latest release is $latest_tag."
elif [[ "$pinned" != "$latest_sha" ]]; then
  say "spec is pinned to $pinned_tag; $latest_tag is out. Bump the submodule (spec docs/sync.md)."
else
  echo "spec is pinned to $pinned_tag, the latest release."
fi
