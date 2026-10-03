#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
retired="$HOME/.config/mac-setup/retired-apps.tsv"

remove_data() {
  local path
  for path in "$@"; do
    [[ -e "$path" || -L "$path" ]] || continue
    printf 'Removing %s\n' "$path"
    rm -rf -- "$path"
  done
}

retire_app() {
  local app="$1" id="$2" root path
  if pgrep -if "/$app.app/Contents/MacOS/" >/dev/null; then
    osascript -e "tell application \"$app\" to quit"
    sleep 1
    if pgrep -if "/$app.app/Contents/MacOS/" >/dev/null; then
      echo "$app is still running; close it before retrying mac-sync." >&2
      return 1
    fi
  fi
  remove_data "/Applications/$app.app" "$HOME/Applications/$app.app"
  for root in 'Application Support' Caches HTTPStorages WebKit Containers 'Application Scripts' Logs; do
    remove_data "$HOME/Library/$root/$id"
  done
  remove_data "$HOME/Library/Preferences/$id.plist" \
    "$HOME/Library/Saved Application State/$id.savedState" \
    "$HOME/Library/HTTPStorages/$id.binarycookies" \
    "$(getconf DARWIN_USER_CACHE_DIR)/$id" "$(getconf DARWIN_USER_TEMP_DIR)/$id"
  for path in "$HOME/Library/Preferences/ByHost/$id".*.plist \
    "$HOME/Library/Logs/DiagnosticReports/$app"-* \
    "$HOME/Library/Application Support/CrashReporter/$app"_*.plist; do
    remove_data "$path"
  done
}

if grep -Fq $'direct\tpi-desktop\t' "$retired"; then
  retire_app 'Pi Desktop' dev.pi.desktop-gui
  # Stop the CLI before deleting its session store. Match only Pi executables.
  pkill -TERM -f '/node_modules/(@earendil-works|@mariozechner)/pi-coding-agent/' || [[ $? == 1 ]]
  for prefix in /opt/homebrew /usr/local "$HOME/.npm-global" "$HOME/.local"; do
    for package in @earendil-works/pi-coding-agent @mariozechner/pi-coding-agent; do
      if [[ -d "$prefix/lib/node_modules/$package" ]]; then
        npm uninstall --global --ignore-scripts --prefix "$prefix" "$package"
      fi
    done
  done
  remove_data "$HOME/.pi" "$HOME/.config/pi" "$HOME/.config/pi-desktop" \
    "$HOME/.cache/pi" "$HOME/.cache/pi-desktop" "$HOME/.local/share/pi" \
    "$HOME/Library/Application Support/Pi Desktop" \
    "$HOME/Library/Application Support/pi-desktop" \
    "$HOME/Library/Caches/Pi Desktop" "$HOME/Library/Caches/pi-desktop" \
    "$HOME/Library/Logs/Pi Desktop" "$HOME/Library/Logs/pi-desktop"
  # Remove only Pi package downloads and npm logs, leaving other npm caches.
  python3 - <<'PY'
import base64
import json
from pathlib import Path
from urllib.parse import unquote

npm = Path.home() / '.npm'
markers = ('pi-coding-agent', 'pi-desktop', '@earendil-works/pi',
           '@mariozechner/pi', 'pi-acp')
cache = npm / '_cacache'
removed = 0
for index in (cache / 'index-v5').glob('*/*/*'):
    if not index.is_file():
        continue
    keep = []
    changed = False
    for line in index.read_text().splitlines(keepends=True):
        try:
            entry = json.loads(line.split('\t', 1)[1])
        except (IndexError, ValueError):
            keep.append(line)
            continue
        if not any(m in unquote(entry.get('key', '')) for m in markers):
            keep.append(line)
            continue
        changed = True
        for integrity in (entry.get('integrity') or '').split():
            algorithm, encoded = integrity.split('-', 1)
            if algorithm not in ('sha1', 'sha256', 'sha384', 'sha512'):
                continue
            digest = base64.b64decode(encoded.split('?', 1)[0]).hex()
            (cache / 'content-v2' / algorithm / digest[:2] / digest[2:4] / digest[4:]).unlink(missing_ok=True)
        removed += 1
    if changed:
        if any(line.strip() for line in keep):
            index.write_text(''.join(keep))
        else:
            index.unlink()
for log in (npm / '_logs').glob('*.log'):
    if any(m in log.read_text(errors='replace') for m in markers):
        log.unlink()
        removed += 1
if removed:
    print(f'Removed {removed} Pi npm cache entries and logs')
PY
fi

if grep -Fq $'cask\tzed\t' "$retired"; then
  retire_app Zed dev.zed.Zed
  if brew list --cask zed >/dev/null 2>&1; then
    brew uninstall --cask zed
  fi
  remove_data "$HOME/.config/zed" "$HOME/.cache/zed" "$HOME/.local/share/zed" \
    "$HOME/Library/Application Support/Zed" "$HOME/Library/Caches/Zed" \
    "$HOME/Library/Logs/Zed" "$HOME/Library/Caches/dev.zed.Zed.ShipIt"
  for path in /opt/homebrew/bin/zed /usr/local/bin/zed "$HOME/.local/bin/zed"; do
    if [[ -L "$path" && "$(readlink "$path")" == *Zed.app/* ]]; then
      remove_data "$path"
    fi
  done
  for path in "$HOME/Library/Caches/Homebrew/Cask/zed"--* \
    "$HOME/Library/Caches/Homebrew/downloads/"*--Zed-*; do
    remove_data "$path"
  done
fi
