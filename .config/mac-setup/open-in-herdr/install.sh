#!/usr/bin/env bash
set -euo pipefail

source_dir="$HOME/.config/mac-setup/open-in-herdr"
app="$HOME/Applications/Open in Herdr.app"
binary="$app/Contents/MacOS/Open in Herdr"
plist="$app/Contents/Info.plist"
register="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

mkdir -p "$app/Contents/MacOS"
if [[ ! -x "$binary" || "$source_dir/main.swift" -nt "$binary" || "$source_dir/Info.plist" -nt "$plist" ]]; then
  swiftc "$source_dir/main.swift" -o "$binary"
  cp "$source_dir/Info.plist" "$plist"
  codesign --force --sign - "$app" >/dev/null
fi

"$register" -f "$app"
"$binary" --set-defaults
