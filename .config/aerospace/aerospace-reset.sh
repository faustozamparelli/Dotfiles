#!/usr/bin/env bash
set -euo pipefail

workspaces=(WEB TERM NOTES DOCS CHAT MEDIA UNI ORG MISC)
focused_workspace="$(aerospace list-workspaces --focused --format '%{workspace}')"

# Reapply the ordered app routing rules to every open window.
aerospace run-callback --for-every-window on-window-detected >/dev/null 2>&1 || true

# Restore regular application windows to the tiled tree. Deliberate overlays
# and small utilities keep their floating behavior.
while IFS=$'\t' read -r window_id bundle_id; do
  [[ -n "$window_id" ]] || continue
  case "$bundle_id" in
    com.raycast.macos|com.steipete.codexbar|org.pqrs.Karabiner-Elements.Settings|org.pqrs.Karabiner-EventViewer|com.goodsnooze.MacWhisper|dev.kdrag0n.MacVirt|ch.protonvpn.mac|com.lihaoyun6.QuickRecorder|com.vorssaint.utils|com.electron.wispr-flow|com.kamenlevi.MagHue|com.tonycoco.Picture-In-Picture|barinov.calculator.ios|net.raymondhill.uBlock-Origin-Lite|com.sielte.MySielteID|io.tailscale.ipn.macsys)
      ;;
    *)
      aerospace layout --window-id "$window_id" tiling >/dev/null 2>&1 || true
      ;;
  esac
done < <(aerospace list-windows --monitor all --format '%{window-id}%{tab}%{app-bundle-id}')

# Accordion with zero padding gives every tiled app the entire workspace.
# Super-H/L changes the visible app; Super-W toggles side-by-side tiles.
for workspace in "${workspaces[@]}"; do
  aerospace layout --workspace "$workspace" --root h_accordion >/dev/null 2>&1 || true
done

[[ -n "$focused_workspace" ]] && aerospace workspace "$focused_workspace" >/dev/null 2>&1 || true
