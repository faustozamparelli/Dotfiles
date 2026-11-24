#!/usr/bin/env bash
set -euo pipefail
# Peekaboo desktop control for Studio and Pro (agents' UI fallback).
# Studio opens the app at login; on Pro agents open it on demand.
[[ "$(uname -m)" == arm64 ]]
case "$(scutil --get ComputerName)" in
  'Mac Studio') desktop_machine=studio ;;
  *'MacBook Pro'*) desktop_machine=pro ;;
  *) echo 'This setup is enabled only for Studio and Pro.' >&2; exit 1 ;;
esac
version=4.9.9
base="https://github.com/openclaw/Peekaboo/releases/download/v$version"
root="$HOME/.local/share/peekaboo/$version"
app='/Applications/Peekaboo.app'
link="$HOME/.local/bin/peekaboo"
if [[ -e "$link" && ! -L "$link" ]]; then echo "Refusing unmanaged $link" >&2; exit 1; fi
if [[ -d "$app" ]]; then
  installed="$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$app/Contents/Info.plist")"
  [[ "$installed" == "$version" ]] || { echo 'Close and review the existing Peekaboo before replacing it.' >&2; exit 1; }
fi
if [[ ! -x "$root/peekaboo" || ! -d "$app" ]]; then
  work="$(mktemp -d "${TMPDIR:-/tmp}/peekaboo.XXXXXX")"
  trap 'rm -rf "$work"' EXIT
  curl -fL --retry 2 --connect-timeout 10 --max-time 180 "$base/peekaboo-macos-arm64.tar.gz" -o "$work/cli.tar.gz"
  curl -fL --retry 2 --connect-timeout 10 --max-time 180 "$base/Peekaboo-$version.app.zip" -o "$work/app.zip"
  printf '%s  %s\n' 8b1dc2c6970169126aa6dcfdcb1bd622fa3b28c9131baf91c9b871dab19f09a0 "$work/cli.tar.gz" 60112aa7c4cd2f050c5e9e8dae2d869f303240e463abbb6d4d3d5f4338f65582 "$work/app.zip" | shasum -a 256 -c -
  mkdir "$work/cli"
  tar -xzf "$work/cli.tar.gz" --strip-components=1 -C "$work/cli"
  /usr/bin/ditto -x -k "$work/app.zip" "$work/app"
  /usr/bin/codesign --verify --strict "$work/cli/peekaboo"
  /usr/bin/codesign --verify --deep --strict "$work/app/Peekaboo.app"
  for signed in "$work/cli/peekaboo" "$work/app/Peekaboo.app"; do
    signing_info="$(/usr/bin/codesign -dv "$signed" 2>&1)"
    /usr/bin/grep -qx 'TeamIdentifier=FWJYW4S8P8' <<< "$signing_info"
  done
  mkdir -p "$root" "$HOME/.local/bin"
  /usr/bin/ditto "$work/cli" "$root"
  [[ -d "$app" ]] || /usr/bin/ditto "$work/app/Peekaboo.app" "$app"
fi
/usr/bin/codesign --verify --strict "$root/peekaboo"
/usr/bin/codesign --verify --deep --strict "$app"
ln -sfn "$root/peekaboo" "$link"
"$link" --version
# Studio keeps the app open through a login item; Pro has none.
for old in pro-desktop studio-desktop; do
  [[ "$old" == "$desktop_machine-desktop" && "$desktop_machine" == studio ]] && continue
  launchctl bootout "gui/$UID/com.fausto.$old" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/com.fausto.$old.plist"
done
[[ "$desktop_machine" == studio ]] || exit 0
agent="$HOME/Library/LaunchAgents/com.fausto.studio-desktop.plist"
mkdir -p "$(dirname "$agent")"
/usr/bin/python3 - "$agent" <<'PY'
from pathlib import Path
import plistlib,sys
path=Path(sys.argv[1])
config={'Label':path.stem,'ProgramArguments':['/usr/bin/open','-g','/Applications/Peekaboo.app'],'RunAtLoad':True}
if path.exists() and plistlib.loads(path.read_bytes()).get('Label') != config['Label']:
    raise RuntimeError('Unexpected login item; refusing replacement')
path.write_bytes(plistlib.dumps(config))
PY
if launchctl print "gui/$UID" >/dev/null 2>&1; then
  launchctl print "gui/$UID/com.fausto.$desktop_machine-desktop" >/dev/null 2>&1 || launchctl bootstrap "gui/$UID" "$agent"
else
  echo 'Peekaboo login item installed; GUI host starts at the next desktop login.'
fi
