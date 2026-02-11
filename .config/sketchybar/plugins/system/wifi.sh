#!/bin/bash

IFACE="en0"
CACHE="${TMPDIR:-/tmp}/sketchybar-wifi-bytes"

POWER="$(networksetup -getairportpower "$IFACE" 2>/dev/null | awk '{print $NF}')"

if [ "$POWER" = "Off" ]; then
  sketchybar --set "$NAME" icon="󰤭" label="off"
  rm -f "$CACHE"
  exit 0
fi

SSID="$(ipconfig getsummary "$IFACE" 2>/dev/null | awk -F' : ' '/^ *SSID/{print $2}' | head -1)"

if [ -z "$SSID" ]; then
  sketchybar --set "$NAME" icon="󰤫" label="--"
  rm -f "$CACHE"
  exit 0
fi

# Read current byte count (non-blocking)
NOW_BYTES="$(netstat -bI "$IFACE" 2>/dev/null | awk 'NR==2{print $7}')"
NOW_TIME="$(date +%s)"

if [ -z "$NOW_BYTES" ]; then
  sketchybar --set "$NAME" icon="󰤨" label="0 Kb/s"
  exit 0
fi

LABEL="0 Kb/s"

# Compare with previous reading
if [ -f "$CACHE" ]; then
  read -r PREV_BYTES PREV_TIME < "$CACHE"
  if [ -n "$PREV_BYTES" ] && [ -n "$PREV_TIME" ]; then
    DELTA_BYTES=$((NOW_BYTES - PREV_BYTES))
    DELTA_TIME=$((NOW_TIME - PREV_TIME))

    if [ "$DELTA_TIME" -gt 0 ] && [ "$DELTA_BYTES" -ge 0 ]; then
      BPS=$((DELTA_BYTES * 8 / DELTA_TIME))

      if [ "$BPS" -ge 1000000 ]; then
        LABEL="$(awk -v b="$BPS" 'BEGIN {printf "%.1f Mb/s", b/1000000}')"
      elif [ "$BPS" -ge 1000 ]; then
        LABEL="$(awk -v b="$BPS" 'BEGIN {printf "%.0f Kb/s", b/1000}')"
      fi
    fi
  fi
fi

echo "$NOW_BYTES $NOW_TIME" > "$CACHE"
sketchybar --set "$NAME" icon="󰤨" label="$LABEL"
