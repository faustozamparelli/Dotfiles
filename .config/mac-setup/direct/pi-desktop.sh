#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

# Pi Desktop launches the separate Pi agent; install it on a fresh Mac too.
if ! command -v pi >/dev/null 2>&1; then
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.87.1
fi

app="/Applications/Pi Desktop.app"
url="https://github.com/FaqFirebase/pi-desktop/releases/download/v0.1.9-alpha/Pi-Desktop-0.1.9-alpha-mac-arm64.zip"
sha256="16df8b2d9242f528f3e6917249887b45fd2e08d21e3944ea6aea896d59d5cc92"

[[ -d "$app" ]] && exit 0
[[ "$(uname -m)" == "arm64" ]] || {
  echo "The pinned Pi Desktop release requires an Apple Silicon Mac." >&2
  exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl --fail --location --silent --show-error "$url" --output "$tmp/Pi-Desktop.zip"
printf '%s  %s\n' "$sha256" "$tmp/Pi-Desktop.zip" | shasum -a 256 --check --status
ditto -x -k "$tmp/Pi-Desktop.zip" "$tmp/unpacked"
source_app="$tmp/unpacked/Pi Desktop.app"
[[ -d "$source_app" ]] || {
  echo "Pi Desktop.app was not found in the verified archive." >&2
  exit 1
}
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")" == "dev.pi.desktop-gui" ]] || {
  echo "The verified archive contains an unexpected application." >&2
  exit 1
}
ditto "$source_app" "$app"
echo "Installed Pi Desktop. Run pi and /login openai-codex once on this Mac."
