#!/bin/bash

source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ] && [ -n "$INFO" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)')"
fi

if [ -z "$VOLUME" ]; then
  VOLUME=0
fi

if [ "$VOLUME" -eq 0 ]; then
  ICON="󰝟"
  COLOR=$MUTED
elif [ "$VOLUME" -lt 35 ]; then
  ICON="󰕿"
  COLOR=$ACCENT
elif [ "$VOLUME" -lt 70 ]; then
  ICON="󰖀"
  COLOR=$ACCENT
else
  ICON="󰕾"
  COLOR=$ACCENT
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOLUME}%"
