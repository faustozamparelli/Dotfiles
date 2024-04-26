#!/bin/bash

sketchybar --add item front_app left \
           --set front_app       background.color=$LEFT_BG_COLOR \
                                 icon.color=$LEFT_COLOR \
                                 icon.font="sketchybar-app-font:Regular:19.0" \
                                 label.color=$LEFT_COLOR \
                                 script="$PLUGIN_DIR/front_app.sh"            \
           --subscribe front_app front_app_switched
