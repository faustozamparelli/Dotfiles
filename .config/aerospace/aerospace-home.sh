#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: aerospace-home.sh <workspace> <bundle-id>" >&2
  exit 2
fi

workspace="$1"
bundle_id="$2"
first_window=""

# Put every existing window for this app back on its predictable home space.
while IFS=$'\t' read -r window_id current_workspace; do
  [[ -n "$window_id" ]] || continue
  [[ "$current_workspace" == "$workspace" ]] || \
    aerospace move-node-to-workspace --window-id "$window_id" "$workspace" >/dev/null 2>&1 || true
  [[ -n "$first_window" ]] || first_window="$window_id"
done < <(
  aerospace list-windows --monitor all --app-bundle-id "$bundle_id" \
    --format '%{window-id}%{tab}%{workspace}' 2>/dev/null || true
)

aerospace workspace "$workspace"
if [[ -n "$first_window" ]]; then
  aerospace focus --window-id "$first_window" >/dev/null 2>&1 || true
else
  open -b "$bundle_id"
fi
