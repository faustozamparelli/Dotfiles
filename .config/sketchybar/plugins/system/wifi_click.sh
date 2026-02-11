#!/bin/bash

IFACE="en0"

STATE="$(networksetup -getairportpower "$IFACE" 2>/dev/null | awk '{print $NF}')"
if [ "$STATE" = "On" ]; then
  networksetup -setairportpower "$IFACE" off
  sketchybar --set wifi icon="󰤭" label="off"
else
  networksetup -setairportpower "$IFACE" on
  sleep 2
  sketchybar --set wifi icon="󰤨" label="on"
fi
