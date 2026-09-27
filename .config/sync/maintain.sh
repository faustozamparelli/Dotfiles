#!/usr/bin/env bash
set -euo pipefail

bare=(git -C "$HOME" --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")

python3 "$HOME/.config/sync/chatgpt-settings.py" capture
"$HOME/.local/bin/mac-sync" --no-pull
"$HOME/.config/keymaps/keymap-docs"
"$HOME/.config/keymaps/keymap-docs" --check

"${bare[@]}" add \
  .gitconfig \
  .config/clangd \
  .config/fish/config.fish \
  .config/fish/fish_plugins \
  .config/fish/functions/sync-maintain.fish \
  .config/ghostty \
  .config/git/.gitignore \
  .config/herdr \
  .config/karabiner/karabiner.json \
  .config/keymaps \
  .config/mac-setup \
  .config/nvim \
  .config/sioyek \
  .config/sync/README.md \
  .config/sync/chatgpt-settings.json \
  .config/sync/chatgpt-settings.py \
  .config/sync/vscode-extensions.txt \
  .config/sync/install-agent.sh \
  .config/sync/maintain.sh \
  .local/bin/mac-app \
  .local/bin/mac-sync \
  .local/bin/vscode-wait \
  "Library/Application Support/Code/User/settings.json" \
  "Library/Application Support/Code/User/keybindings.json" \
  README.md

"${bare[@]}" status --short
