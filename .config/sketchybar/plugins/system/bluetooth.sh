#!/bin/bash

source "$CONFIG_DIR/colors.sh"

if command -v blueutil >/dev/null 2>&1; then
  STATE="$(blueutil -p 2>/dev/null)"
  if [ "$STATE" = "1" ]; then
    sketchybar --set "$NAME" icon="󰂯" icon.color=$ACCENT
  else
    sketchybar --set "$NAME" icon="󰂲" icon.color=$MUTED
  fi
else
  sketchybar --set "$NAME" icon="󰂲" icon.color=$MUTED
fi
