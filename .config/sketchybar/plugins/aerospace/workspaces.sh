#!/bin/bash

source "$CONFIG_DIR/colors.sh"

FOCUSED="$(aerospace list-workspaces --focused 2>/dev/null | head -n1)"
if [ -z "$FOCUSED" ]; then
  exit 0
fi

ID="${NAME#space.}"

APPS="$(aerospace list-windows --workspace "$ID" --json 2>/dev/null | jq -r '.[]."app-name"' | awk '!seen[$0]++')"
ICON_STR=""
if [ -n "$APPS" ]; then
  while IFS= read -r app; do
    ICON_STR+="$($CONFIG_DIR/plugins/system/icon_map.sh "$app") "
  done <<< "$APPS"
fi

ICON_STR="${ICON_STR%% }"

HAS_APPS=false
[ -n "$ICON_STR" ] && HAS_APPS=true

IS_FOCUSED=false
[ "$ID" = "$FOCUSED" ] && IS_FOCUSED=true

# Only show workspaces that are focused or have apps
if [ "$HAS_APPS" = false ] && [ "$IS_FOCUSED" = false ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

sketchybar --set "$NAME" drawing=on

if [ "$HAS_APPS" = true ]; then
  sketchybar --set "$NAME" label="$ICON_STR" label.drawing=on
else
  sketchybar --set "$NAME" label="" label.drawing=off
fi

if [ "$IS_FOCUSED" = true ]; then
  sketchybar --set "$NAME" background.color=$ACCENT \
                         background.border_color=$ACCENT \
                         icon.color=$TEXT \
                         label.color=$TEXT
else
  sketchybar --set "$NAME" background.color=$ITEM_BG_ALT \
                         background.border_color=$ACCENT_DARK \
                         icon.color=$MUTED \
                         label.color=$MUTED
fi
