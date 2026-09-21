#!/usr/bin/env bash
set -euo pipefail

# One startup pass only: no polling process and no battery overhead.
routes=(
  'WEB|net.imput.helium'
  'TERM|com.mitchellh.ghostty'
  'TERM|com.t3tools.t3code'
  'TERM|com.microsoft.VSCode'
  'CHAT|com.automattic.beeper.desktop'
  'CHAT|com.hnc.Discord'
  'NOTES|notion.id'
  'DOCS|info.sioyek.sioyek'
  'DOCS|com.microsoft.Excel'
  'MEDIA|com.spotify.client'
)

for route in "${routes[@]}"; do
  workspace="${route%%|*}"
  bundle_id="${route#*|}"
  while IFS= read -r window_id; do
    [[ -n "$window_id" ]] || continue
    aerospace move-node-to-workspace --window-id "$window_id" "$workspace" >/dev/null 2>&1 || true
  done < <(
    aerospace list-windows --monitor all --app-bundle-id "$bundle_id" \
      --format '%{window-id}' 2>/dev/null || true
  )
done
