#!/bin/bash

PIDFILE="${TMPDIR:-/tmp}/sketchybar-aerospace.pid"

if [ -f "$PIDFILE" ]; then
  read -r OLD_PID < "$PIDFILE"
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null
    wait "$OLD_PID" 2>/dev/null
  fi
fi

echo $$ > "$PIDFILE"

LAST_WS=""
LAST_HASH=""
TICK=0

while true; do
  CURRENT="$(aerospace list-workspaces --focused 2>/dev/null | head -n1)"
  if [ -n "$CURRENT" ] && [ "$CURRENT" != "$LAST_WS" ]; then
    LAST_WS="$CURRENT"
    sketchybar --trigger aerospace_workspace_change
  fi

  # Check window layout every 5 ticks (5 seconds)
  if [ $((TICK % 5)) -eq 0 ]; then
    HASH="$(aerospace list-windows --all --json 2>/dev/null | shasum -a 256 | awk '{print $1}')"
    if [ -n "$HASH" ] && [ "$HASH" != "$LAST_HASH" ]; then
      LAST_HASH="$HASH"
      sketchybar --trigger aerospace_workspace_change
    fi
  fi

  TICK=$((TICK + 1))
  sleep 1
done
