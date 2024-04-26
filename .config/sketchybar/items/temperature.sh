#!/bin/bash

sketchybar --add item temperature right \
           --set temperature update_freq=20 \
                             icon=􀇬  \
                             script="$PLUGIN_DIR/temperature.sh"
