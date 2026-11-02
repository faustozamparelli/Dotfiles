#!/usr/bin/env bash
# Retire the superseded AC auto-connect watcher; VPN sessions are now manual.
set -euo pipefail

for domain in "gui/$UID" "user/$UID"; do
  label="$domain/com.fausto.tailscale-power"
  if launchctl print "$label" >/dev/null 2>&1; then
    launchctl bootout "$label"
  fi
done

backup=""
for legacy_file in \
  "$HOME/Library/LaunchAgents/com.fausto.tailscale-power.plist" \
  "$HOME/.local/bin/tailscale-power" \
  "$HOME/.local/libexec/tailscale-power.swift"; do
  if [[ -e "$legacy_file" ]]; then
    if [[ -z "$backup" ]]; then
      mkdir -p "$HOME/.local/state/air-power"
      backup="$(mktemp -d "$HOME/.local/state/air-power/retired-autoconnect.XXXXXX")"
    fi
    mv "$legacy_file" "$backup/"
  fi
done
