#!/usr/bin/env bash
set -euo pipefail

focused_record="$(aerospace list-windows --focused --format '%{window-id}%{tab}%{workspace}')"
[[ -n "$focused_record" ]] || exit 0
IFS=$'\t' read -r focused_window focused_workspace <<< "$focused_record"

focused_monitor="$(aerospace list-monitors --focused --format '%{monitor-id}')"
other_monitor=""
while IFS= read -r monitor; do
  if [[ -n "$monitor" && "$monitor" != "$focused_monitor" ]]; then
    other_monitor="$monitor"
    break
  fi
done < <(aerospace list-monitors --format '%{monitor-id}')

[[ -n "$other_monitor" ]] || exit 0
other_workspace="$(aerospace list-workspaces --monitor "$other_monitor" --visible --format '%{workspace}' | awk 'NR == 1 { first = $0 } END { print first }')"
[[ -n "$other_workspace" ]] || exit 0

# AeroSpace has one global focus. On the other display, prefer the first tiled
# window in its visible workspace and fall back to a floating window.
other_records="$(aerospace list-windows --workspace "$other_workspace" --format '%{window-id}%{tab}%{window-layout}')"
other_window="$(awk -F '\t' '$2 != "floating" { print $1; exit }' <<< "$other_records")"
[[ -n "$other_window" ]] || other_window="$(awk -F '\t' 'NF { print $1; exit }' <<< "$other_records")"
[[ -n "$other_window" ]] || exit 0

aerospace move-node-to-workspace --window-id "$other_window" "$focused_workspace"
aerospace move-node-to-workspace --window-id "$focused_window" "$other_workspace"
