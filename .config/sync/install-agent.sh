#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d "$HOME/.config/git/dotfiles" || ! -f "$HOME/.config/mac-setup/apps.tsv" ]]; then
  echo "Dotfiles are not checked out yet. Follow the New Mac section in ~/README.md." >&2
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Follow the New Mac section in ~/README.md." >&2
  exit 1
fi

chmod +x \
  "$HOME/.local/bin/mac-app" \
  "$HOME/.local/bin/mac-sync" \
  "$HOME/.config/mac-setup/direct/"*.sh \
  "$HOME/.config/keymaps/keymap-docs" \
  "$HOME/.config/sync/maintain.sh"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
agent="$HOME/Library/LaunchAgents/com.fausto.mac-sync.plist"
sed "s|__HOME__|$HOME|g" "$HOME/.config/mac-setup/com.fausto.mac-sync.plist" > "$agent"
domain="user/$UID"
if launchctl print "gui/$UID" >/dev/null 2>&1; then
  domain="gui/$UID"
fi
for previous_domain in "gui/$UID" "user/$UID"; do
  launchctl bootout "$previous_domain/com.fausto.mac-sync" 2>/dev/null || true
done

sync_status=0
"$HOME/.local/bin/mac-sync" --no-pull || sync_status=$?

launchctl enable "$domain/com.fausto.mac-sync"
launchctl bootstrap "$domain" "$agent"

echo "Automatic sync is installed in $domain. Shared apps sync at login and once per hour."
echo "Some apps still require one-time macOS privacy, helper, or App Store approval."
if ((sync_status)); then
  echo "Initial sync had errors; automatic sync remains enabled. Resolve the messages above and rerun mac-sync." >&2
fi
exit "$sync_status"
