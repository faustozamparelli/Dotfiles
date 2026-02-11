#!/bin/bash

if command -v blueutil >/dev/null 2>&1; then
  STATE="$(blueutil -p 2>/dev/null)"
  if [ "$STATE" = "1" ]; then
    blueutil -p 0
  else
    blueutil -p 1
  fi
fi
