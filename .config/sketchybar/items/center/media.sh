#!/bin/bash

# Commented out event subscription to prevent blocking Spotify from quitting
# sketchybar --add event spotify_change com.spotify.client.PlaybackStateChanged

sketchybar --add item media left \
           --set media icon.drawing=off \
                       label="" \
                        label.font=".SF NS:Medium:14.0" \
                       label.max_chars=30 \
                       label.color=$MUTED \
                       scroll_texts=off \
                       drawing=off \
                       background.drawing=off \
                       padding_left=4 \
                       padding_right=4 \
                       label.padding_left=6 \
                       label.padding_right=6 \
                       update_freq=5 \
                       click_script="$PLUGIN_DIR/media/click.sh" \
                       script="$PLUGIN_DIR/media/status.sh"
           # Removed event subscription - now relies only on periodic updates
