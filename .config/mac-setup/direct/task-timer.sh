#!/usr/bin/env bash
set -euo pipefail

# Shared Task Timer release. Update the version, URL and checksum together.
version="1.0.1"
url="https://github.com/faustozamparelli/TaskTimer/releases/download/v1.0.1/TaskTimer-1.0.1-macos-arm64.zip"
sha256="1c4cf087191fd7aa48ff917de28d3988f4895a54be2dbf40eaad67b7a16d6bf3"
destination="/Applications/Task Timer.app"
binary="$destination/Contents/MacOS/TaskTimer"

[[ "$(uname -m)" == arm64 ]] || { echo "Task Timer requires Apple silicon." >&2; exit 1; }
installed_version() { /usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$destination/Contents/Info.plist" 2>/dev/null || true; }
ensure_login() { "$binary" --login enable; }
if [[ -d "$destination" ]]; then
  identifier="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$destination/Contents/Info.plist" 2>/dev/null || true)"
  [[ "$identifier" == com.fausto.TaskTimer ]] || { echo "Refusing to replace an unrelated Task Timer.app." >&2; exit 1; }
fi
if [[ "$(installed_version)" == "$version" ]]; then
  /usr/bin/codesign --verify --strict "$destination"
  ensure_login
  exit 0
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/task-timer-install.XXXXXX")"
replacement="/Applications/.TaskTimer-install-$$.app"
backup="/Applications/.TaskTimer-previous-$$.app"
cleanup() {
  rm -rf "$work" "$replacement"
  if [[ -d "$backup" && ! -e "$destination" ]]; then mv "$backup" "$destination"; fi
}
trap cleanup EXIT
curl --fail --location --retry 3 --connect-timeout 10 --max-time 120 "$url" -o "$work/app.zip"
printf '%s  %s\n' "$sha256" "$work/app.zip" | /usr/bin/shasum -a 256 -c -
/usr/bin/ditto -x -k "$work/app.zip" "$work/unpacked"
staged="$work/unpacked/Task Timer.app"
/usr/bin/codesign --verify --strict "$staged"
[[ "$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$staged/Contents/Info.plist")" == com.fausto.TaskTimer ]]
[[ "$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$staged/Contents/Info.plist")" == "$version" ]]

# A concurrent installer may already have completed while the download ran.
if [[ "$(installed_version)" == "$version" ]]; then ensure_login; exit 0; fi
was_running=false
pids="$(/usr/bin/pgrep -f '/Applications/Task Timer[.]app/Contents/MacOS/[T]askTimer' || true)"
if [[ -n "$pids" ]]; then
  if [[ "$(installed_version)" == 1.0 ]]; then
    echo "Quit the old Task Timer prototype to install $version; its task is preserved."
    exit 0
  fi
  reply="$("$binary" --quit-if-idle 2>/dev/null || true)"
  quitting="$(printf '%s' "$reply" | /usr/bin/plutil -extract quitting raw -o - - 2>/dev/null || true)"
  if [[ "$quitting" != true ]]; then
    echo "Task Timer is busy; the update will retry after its task and popover are closed."
    exit 0
  fi
  was_running=true
  for app_pid in $pids; do
    for ((attempt=0; attempt<50; attempt++)); do
      kill -0 "$app_pid" 2>/dev/null || break
      sleep 0.1
    done
    if kill -0 "$app_pid" 2>/dev/null; then echo "Task Timer did not quit; update deferred."; exit 0; fi
  done
fi

/usr/bin/ditto "$staged" "$replacement"
if [[ -d "$destination" ]]; then mv "$destination" "$backup"; fi
mv "$replacement" "$destination"
rm -rf "$backup"
ensure_login
if $was_running || /bin/launchctl print "gui/$(id -u)" >/dev/null 2>&1; then
  /usr/bin/open -g "$destination" --args --background
fi
echo "Installed Task Timer $version with launch at login."
