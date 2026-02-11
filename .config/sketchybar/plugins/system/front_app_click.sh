#!/bin/bash

APP="$(sketchybar --query front_app | jq -r '.label.value')"
if [ -n "$APP" ] && [ "$APP" != "--" ]; then
  open -a "$APP"
fi
