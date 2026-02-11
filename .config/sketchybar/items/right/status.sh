#!/bin/bash

sketchybar --add item calendar right \
           --set calendar icon="󰃶" \
                          icon.font="Iosevka NFM:Regular:22.0" \
                          icon.color=$ACCENT \
                          label.font="$LABEL_FONT_BOLD" \
                          update_freq=30 \
                          click_script="open -a Calendar" \
                          script="$PLUGIN_DIR/system/calendar.sh"

sketchybar --add item bluetooth right \
           --set bluetooth icon="󰂯" \
                           icon.font="Iosevka NFM:Regular:22.0" \
                           icon.color=$ACCENT \
                           label.drawing=off \
                           update_freq=15 \
                           click_script="$PLUGIN_DIR/system/bluetooth_click.sh" \
                           script="$PLUGIN_DIR/system/bluetooth.sh"

sketchybar --add item wifi right \
           --set wifi icon="󰤨" \
                      icon.font="Iosevka NFM:Regular:22.0" \
                      icon.color=$ACCENT \
                      label.drawing=on \
                      update_freq=10 \
                      click_script="$PLUGIN_DIR/system/wifi_click.sh" \
                      script="$PLUGIN_DIR/system/wifi.sh"

sketchybar --add item volume right \
           --set volume icon="󰕾" \
                        icon.font="Iosevka NFM:Regular:22.0" \
                        icon.color=$ACCENT \
                        script="$PLUGIN_DIR/system/volume.sh" \
           --subscribe volume volume_change

sketchybar --add item battery right \
           --set battery icon="󰁹" \
                         icon.font="Iosevka NFM:Regular:22.0" \
                         icon.color=$GOOD \
                         label.drawing=on \
                         update_freq=60 \
                         click_script="open -a 'AlDente'" \
                         script="$PLUGIN_DIR/system/battery.sh" \
           --subscribe battery system_woke power_source_change
