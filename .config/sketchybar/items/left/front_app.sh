#!/bin/bash

sketchybar --add item front_app left \
           --set front_app icon="󰣆" \
                            icon.font="Iosevka NFM:Regular:22.0" \
                            icon.color=$ACCENT \
                            label="--" \
                            label.font="$LABEL_FONT_BOLD" \
                            background.color=$ITEM_BG \
                            click_script="$PLUGIN_DIR/system/front_app_click.sh" \
                            script="$PLUGIN_DIR/system/front_app.sh" \
           --subscribe front_app front_app_switched
