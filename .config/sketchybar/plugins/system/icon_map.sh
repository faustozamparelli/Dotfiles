#!/bin/bash

case "$1" in
  "Ghostty" | "Terminal" | "iTerm2" | "Alacritty" | "WezTerm" | "kitty")
    echo "󰆍"
    ;;
  "Code" | "Visual Studio Code" | "VSCodium")
    echo "󰨞"
    ;;
  "Cursor")
    echo "󰨞"
    ;;
  "Arc" | "Safari" | "Google Chrome" | "Google Chrome Canary" | "Firefox" | "Brave Browser" | "Browser" | "Zen")
    echo "󰖟"
    ;;
  "Obsidian" | "Notes" | "Notes.app")
    echo "󱞁"
    ;;
  "MailMate" | "Mail" | "Spark" | "Canary Mail")
    echo "󰇮"
    ;;
  "Calendar" | "Fantastical" | "Cron")
    echo "󰃶"
    ;;
  "WhatsApp" | "Messages" | "Legcord" | "Discord" | "Telegram")
    echo "󰍡"
    ;;
  "Spotify" | "Music")
    echo "󰎆"
    ;;
  "Finder")
    echo "󰀶"
    ;;
  "System Settings" | "System Preferences")
    echo "󰒓"
    ;;
  "Preview" | "Pixelmator" | "Photos")
    echo "󰋩"
    ;;
  "Figma")
    echo "󰡁"
    ;;
  "Slack")
    echo "󰒱"
    ;;
  *)
    echo "󰣆"
    ;;
esac
