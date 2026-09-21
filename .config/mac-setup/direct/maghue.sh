#!/usr/bin/env bash
set -euo pipefail

app="/Applications/MagHue.app"
url="https://github.com/kamenlevi/MagHue/releases/download/v1.0.0/MagHue.zip"
sha256="084fb133006c9d8ddbf662d0daa13a7846b2300477a29b55ff93b510e03f6d55"

[[ -d "$app" ]] && exit 0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl --fail --location --silent --show-error "$url" --output "$tmp/MagHue.zip"
printf '%s  %s\n' "$sha256" "$tmp/MagHue.zip" | shasum -a 256 --check --status
ditto -x -k "$tmp/MagHue.zip" "$tmp/unpacked"
source_app="$(find "$tmp/unpacked" -maxdepth 2 -name 'MagHue.app' -type d -print -quit)"
[[ -n "$source_app" ]] || { echo "MagHue.app was not found in the verified archive" >&2; exit 1; }
ditto "$source_app" "$app"
echo "Installed MagHue. Open it once to approve its privileged helper."
