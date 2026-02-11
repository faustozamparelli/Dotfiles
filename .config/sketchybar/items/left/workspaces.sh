#!/bin/bash

sketchybar --add event aerospace_workspace_change

for sid in 1 2 3 4 5 6 7 8 9; do
  sketchybar --add item space.$sid left \
             --set space.$sid icon="$sid" \
                              icon.font=".SF NS:Bold:13.0" \
                              icon.align=center \
                              icon.width=20 \
                               icon.padding_left=5 \
                               icon.padding_right=5 \
                              label.drawing=on \
                              label.font="Iosevka NFM:Regular:22.0" \
                              label.color=$MUTED \
                               label.padding_left=2 \
                               label.padding_right=5 \
                              background.color=$ITEM_BG_ALT \
                              background.border_color=$ACCENT_DARK \
                              background.corner_radius=9 \
                              drawing=off \
                              script="$PLUGIN_DIR/aerospace/workspaces.sh" \
                              click_script="aerospace workspace $sid" \
             --subscribe space.$sid aerospace_workspace_change
done

sketchybar --trigger aerospace_workspace_change
