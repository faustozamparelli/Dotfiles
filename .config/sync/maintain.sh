#!/usr/bin/env bash
set -euo pipefail

bare=(git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")

"$HOME/.local/bin/mac-sync" --no-pull
"$HOME/.config/keymaps/keymap-docs"
"$HOME/.config/keymaps/keymap-docs" --check

"${bare[@]}" add \
  .gitconfig \
  .config/aerospace \
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
  .config/sync/install-agent.sh \
  .config/sync/maintain.sh \
  .local/bin/mac-app \
  .local/bin/mac-sync \
  README.md

"${bare[@]}" status --short
