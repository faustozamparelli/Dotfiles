#!/bin/bash

sketchybar --add item cpu right \
           --set cpu  update_freq=40 \
                      icon=􀧓  \
                      script="$PLUGIN_DIR/cpu.sh"
