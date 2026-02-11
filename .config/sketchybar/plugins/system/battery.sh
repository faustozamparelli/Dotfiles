#!/bin/bash

source "$CONFIG_DIR/colors.sh"

PERCENTAGE=$(pmset -g batt | grep -o '[0-9]\+%' | head -1 | tr -d '%')
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" icon="󰂑" label="--"
  exit 0
fi

if [ "$PERCENTAGE" -ge 90 ]; then
  ICON="󰁹"
  COLOR=$GOOD
elif [ "$PERCENTAGE" -ge 60 ]; then
  ICON="󰂀"
  COLOR=$GOOD
elif [ "$PERCENTAGE" -ge 30 ]; then
  ICON="󰁾"
  COLOR=$TEXT
elif [ "$PERCENTAGE" -ge 10 ]; then
  ICON="󰁻"
  COLOR=$WARNING
else
  ICON="󰂎"
  COLOR=$WARNING
fi

if [ -n "$CHARGING" ]; then
  ICON="󰂄"
  COLOR=$ACCENT
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
