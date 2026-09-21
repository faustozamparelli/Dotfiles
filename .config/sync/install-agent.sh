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
  "$HOME/.config/aerospace/aerospace-home.sh" \
  "$HOME/.config/aerospace/aerospace-reset.sh" \
  "$HOME/.config/aerospace/aerospace-swap-monitor-windows.sh" \
  "$HOME/.config/mac-setup/direct/"*.sh \
  "$HOME/.config/keymaps/keymap-docs" \
  "$HOME/.config/sync/maintain.sh"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
agent="$HOME/Library/LaunchAgents/com.fausto.mac-sync.plist"
sed "s|__HOME__|$HOME|g" "$HOME/.config/mac-setup/com.fausto.mac-sync.plist" > "$agent"
launchctl bootout "gui/$UID/com.fausto.mac-sync" 2>/dev/null || true

"$HOME/.local/bin/mac-sync" --no-pull

launchctl bootstrap "gui/$UID" "$agent"

echo "Mac setup is installed. Shared apps now sync at login and once per hour."
echo "Some apps still require one-time macOS privacy, helper, or App Store approval."
