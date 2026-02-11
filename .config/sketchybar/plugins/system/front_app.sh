#!/bin/bash

APP="$INFO"
ICON="$($CONFIG_DIR/plugins/system/icon_map.sh "$APP")"

if [ -z "$ICON" ]; then
  ICON=""
fi

sketchybar --set "$NAME" icon="$ICON" label="$APP"
