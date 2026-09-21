#!/usr/bin/env bash
set -euo pipefail

app="/Applications/Sioyek.app"
url="https://github.com/ahrm/sioyek/releases/download/v2.0.0/sioyek-release-mac.zip"
sha256="0f81831d4fa0d57e7e7e56a40ab6fa6488950b7d6a944aa29918be42cfc46b8a"

[[ -d "$app" ]] && exit 0

tmp="$(mktemp -d)"
mountpoint="$tmp/mount"
mounted=false
cleanup() {
  $mounted && hdiutil detach "$mountpoint" -quiet 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

curl --fail --location --silent --show-error "$url" --output "$tmp/sioyek.zip"
printf '%s  %s\n' "$sha256" "$tmp/sioyek.zip" | shasum -a 256 --check --status
ditto -x -k "$tmp/sioyek.zip" "$tmp/unpacked"
mkdir "$mountpoint"
hdiutil attach -nobrowse -readonly -mountpoint "$mountpoint" "$tmp/unpacked/build/sioyek.dmg" >/dev/null
mounted=true
[[ -d "$mountpoint/sioyek.app" ]] || { echo "sioyek.app was not found in the verified image" >&2; exit 1; }
ditto "$mountpoint/sioyek.app" "$app"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string Sioyek' "$app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName Sioyek' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Sioyek' "$app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Sioyek' "$app/Contents/Info.plist"
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
echo "Installed sioyek from its checksum-pinned official release."
