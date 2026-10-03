#!/usr/bin/env bash
set -euo pipefail

bare=(git -C "$HOME" --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")

python3 "$HOME/.config/sync/codex-technical.py" capture
"$HOME/.local/bin/mac-sync" --no-pull
"$HOME/.config/keymaps/keymap-docs"
"$HOME/.config/keymaps/keymap-docs" --check

"${bare[@]}" add -u -- .config/sync
"${bare[@]}" add \
  .gitconfig \
  .agents/skills/context7-mcp \
  .codex/skills/context7-docs \
  .codex/skills/grill-me \
  .codex/skills/spam-senders \
  .config/duti/defaults.duti \
  .config/fish/config.fish \
  .config/fish/fish_plugins \
  .config/fish/functions/sync-maintain.fish \
  .config/gh/config.yml \
  .config/ghostty \
  .config/git/.gitignore \
  .config/herdr \
  .config/karabiner/karabiner.json \
  .config/keymaps \
  .config/jj/config.toml \
  .config/mac-setup \
  .config/nvim \
  .config/sync/README.md \
  .config/sync/codex-technical.json \
  .config/sync/codex-technical.py \
  .config/sync/vscode-extensions.txt \
  .config/sync/install-agent.sh \
  .config/sync/maintain.sh \
  .local/bin/mac-app \
  .local/bin/mac-sync \
  .codexbar/config.json \
  "Library/Application Support/Code/User/settings.json" \
  "Library/Application Support/Code/User/keybindings.json" \
  README.md

"${bare[@]}" status --short
