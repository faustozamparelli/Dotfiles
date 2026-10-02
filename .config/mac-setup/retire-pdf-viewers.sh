#!/usr/bin/env bash
# Explicit, idempotent retirement of PDF viewer software; never remove PDFs.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
failed=0
remove() {
  for path in "$@"; do
    [[ -e "$path" || -L "$path" ]] || continue
    printf 'Removing PDF viewer data: %s\n' "$path"
    rm -rf -- "$path" || failed=1
  done
}

# Quit rather than kill so unsaved document edits get a chance to be saved.
for app in Highlights Negative Sioyek MuPDF mupdf; do
  if pgrep -if "/${app}.app/Contents/MacOS/" >/dev/null; then
    osascript -e "tell application \"$app\" to quit" || failed=1
    sleep 1
    if pgrep -if "/${app}.app/Contents/MacOS/" >/dev/null; then
      echo "Cannot remove $app while it is still running (check save dialogs)." >&2
      exit 1
    fi
  fi
done

# Remove old appearance automation before its scripts/app disappear.
for agent in "$HOME"/Library/LaunchAgents/*[Ss]ioyek*.plist; do
  [[ -f "$agent" ]] || continue
  launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true
  remove "$agent"
done
for token in sioyek mupdf; do
  if brew list --cask "$token" >/dev/null 2>&1; then
    brew uninstall --cask --zap "$token" || { brew uninstall --cask --force "$token" || failed=1; }
  fi
done
if brew list --formula --versions mupdf >/dev/null 2>&1; then
  brew uninstall --formula mupdf || failed=1
fi

for app in Highlights Negative Sioyek sioyek MuPDF mupdf; do
  path="/Applications/$app.app"
  if [[ -d "$path" && ! -w "$path/Contents" ]]; then
    # Scheduled sync never prompts; a terminal can authorize with sudo -v.
    sudo -n /bin/rm -rf -- "$path" || failed=1
  else
    remove "$path"
  fi
  remove "$HOME/Applications/$app.app"
done
remove "$HOME/.config/sioyek" "$HOME/.config/mupdf" "$HOME/.mupdf" \
  "$HOME/.cache/sioyek" "$HOME/.cache/mupdf" \
  "$HOME/.local/share/sioyek" "$HOME/.local/share/mupdf" \
  "$HOME/Library/Application Support/Sioyek" "$HOME/Library/Application Support/sioyek" \
  "$HOME/Library/Application Support/MuPDF" "$HOME/Library/Application Support/mupdf" \
  "$HOME/Library/Logs/sioyek-system-theme.log"

# Exact bundle identifiers, including sandbox containers and WebKit caches.
cache_root="$(getconf DARWIN_USER_CACHE_DIR)"
temp_root="$(getconf DARWIN_USER_TEMP_DIR)"
for id in net.highlightsapp.universal pl.mackozer.Negative info.sioyek.sioyek com.artifex.mupdf; do
  for root in "Application Support" "Caches" "HTTPStorages" "WebKit" "Containers" "Application Scripts"; do
    remove "$HOME/Library/$root/$id"
  done
  remove "$HOME/Library/Preferences/$id.plist" \
    "$HOME/Library/Saved Application State/$id.savedState" \
    "$HOME/Library/HTTPStorages/$id.binarycookies" "$cache_root/$id" "$temp_root/$id"
  for path in "$HOME/Library/Preferences/ByHost/$id".*.plist \
    "$cache_root"/com.apple.WebKit.*+"$id"; do
    remove "$path"
  done
done
for path in "$HOME"/Library/Logs/DiagnosticReports/[Ss]ioyek-* \
  "$HOME"/Library/Logs/DiagnosticReports/Highlights-* \
  "$HOME"/Library/Logs/DiagnosticReports/Negative-* \
  "$HOME"/Library/Logs/DiagnosticReports/[Mm]u[Pp][Dd][Ff]-* \
  "$HOME"/Library/Application\ Support/CrashReporter/[Ss]ioyek_*.plist \
  "$HOME"/Library/Caches/Homebrew/*mupdf* \
  "$HOME"/Library/Caches/Homebrew/*sioyek* \
  "$HOME"/Library/Caches/Homebrew/downloads/*--mupdf* \
  "$HOME"/Library/Caches/Homebrew/downloads/*--sioyek* \
  /Applications/.sioyek-codex-new /Applications/.sioyek-codex-old; do
  remove "$path"
done
# Only remove an empty iCloud app directory; cloud documents are not software.
rmdir "$HOME/Library/Mobile Documents/iCloud~net~highlightsapp/Documents" 2>/dev/null || true
rmdir "$HOME/Library/Mobile Documents/iCloud~net~highlightsapp" 2>/dev/null || true
exit "$failed"
