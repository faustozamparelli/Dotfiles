#!/bin/bash

if pgrep -x "Spotify" >/dev/null 2>&1; then
  # Use timeout to prevent hanging AppleScript calls
  timeout 2 osascript -e '
    try
      tell application "Spotify" to playpause
    on error
      return
    end try
  ' 2>/dev/null
  sleep 0.3
  "$CONFIG_DIR/plugins/media/status.sh"
fi
