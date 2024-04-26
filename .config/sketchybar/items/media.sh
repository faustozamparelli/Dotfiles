#!/bin/bash

sketchybar --add item media q\
           --set media label.color=$MUSIC \
                       label.max_chars=35 \
                       label.font="SF Pro:Semibold:17.0" \
                       scroll_texts=off \
                       icon=􀑪             \
                       icon.color=$MUSIC \
                       background.color=$MUSIC_BG \
                       background.drawing=off \
                       script="$PLUGIN_DIR/media.sh" \
           --subscribe media media_change
