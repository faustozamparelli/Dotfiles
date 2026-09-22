#!/usr/bin/env bash
set -euo pipefail

focused_workspace="$(aerospace list-workspaces --focused --format '%{workspace}')"
[[ -n "$focused_workspace" ]] || exit 0

focused_monitor="$(aerospace list-monitors --focused --format '%{monitor-id}')"
other_monitor=""
while IFS= read -r monitor; do
  if [[ -n "$monitor" && "$monitor" != "$focused_monitor" ]]; then
    other_monitor="$monitor"
    break
  fi
done < <(aerospace list-monitors --format '%{monitor-id}')

[[ -n "$other_monitor" ]] || exit 0
other_workspace="$(aerospace list-workspaces --monitor "$other_monitor" --visible --format '%{workspace}')"
[[ -n "$other_workspace" ]] || exit 0

# Move the visible workspaces, keeping every window in its assigned workspace.
aerospace move-workspace-to-monitor --workspace "$focused_workspace" "$other_monitor"
aerospace move-workspace-to-monitor --workspace "$other_workspace" "$focused_monitor"
