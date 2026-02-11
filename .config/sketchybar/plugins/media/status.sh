#!/bin/bash

# Check if Spotify process exists
if ! pgrep -x "Spotify" >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Quick test to see if Spotify is responsive - if not, it might be quitting
if ! osascript -e 'tell application "Spotify" to get name' >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Only proceed with full status check if Spotify is responsive
INFO="$(osascript -e '
  try
    tell application "Spotify"
      if player state is playing then
        return "playing|" & name of current track & "|" & artist of current track
      else if player state is paused then
        return "paused|" & name of current track & "|" & artist of current track
      else
        return "stopped||"
      end if
    end tell
  on error
    return "error||"
  end try
' 2>/dev/null)"

STATE="$(echo "$INFO" | cut -d'|' -f1)"
TITLE="$(echo "$INFO" | cut -d'|' -f2)"
ARTIST="$(echo "$INFO" | cut -d'|' -f3)"

# If we get an error, assume Spotify is quitting and hide the widget
if [ "$STATE" = "error" ] || [ -z "$INFO" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if [ -n "$TITLE" ] && [ "$STATE" != "stopped" ]; then
  sketchybar --set "$NAME" drawing=on label="${TITLE} - ${ARTIST}"
  exit 0
fi

sketchybar --set "$NAME" drawing=off
