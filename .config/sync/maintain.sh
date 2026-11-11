#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

bare=(git -C "$HOME" --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")

python3 "$HOME/.config/sync/codex-technical.py" capture
python3 "$HOME/.config/sync/app-preferences.py" capture
python3 "$HOME/.config/sync/helium-apps.py" capture
MAC_SYNC_DEFER_WEB_APP_REPORT=1 "$HOME/.local/bin/mac-sync" --no-pull
"$HOME/.config/keymaps/keymap-docs"
"$HOME/.config/keymaps/keymap-docs" --check

"${bare[@]}" add -u -- .config/sync
"${bare[@]}" add -u -- .codex/AGENTS.md .ssh/config .local/bin/air-power-setup .local/bin/remote
"${bare[@]}" add \
  .config/sync/vscode-markdown-preview-wrap \
  .gitconfig \
  .config/duti/defaults.duti \
  .config/fish/config.fish \
  .config/fish/fish_plugins \
  .config/fish/functions/sync-maintain.fish \
  .config/gh/config.yml \
  .config/ghostty \
  .hammerspoon/init.lua \
  .config/git/.gitignore \
  .config/herdr \
  .config/karabiner/karabiner.json \
  .config/keymaps \
  .config/qalculate/qalc.cfg \
  .config/mac-setup \
  .local/bin/mac-app \
  .local/bin/mac \
  .local/bin/helium-extension \
  .local/bin/mac-sync \
  .local/bin/mac-update \
  .local/bin/awake \
  "Library/Application Support/Code/User/settings.json" \
  "Library/Application Support/Code/User/keybindings.json" \
  "Library/Application Support/Code/User/tasks.json" \
  README.md

"${bare[@]}" status --short

if [[ "${MAC_SYNC_DEFER_WEB_APP_REPORT:-0}" != 1 ]]; then
  python3 "$HOME/.config/sync/manual-actions.py"
fi
