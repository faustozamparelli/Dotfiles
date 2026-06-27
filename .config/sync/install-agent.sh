#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d "$HOME/.config/git/dotfiles" || ! -f "$HOME/.config/sync/README.md" ]]; then
  echo "Dotfiles are not checked out yet." >&2
  echo "Open the repository README on GitHub and complete the 'New Mac: Get To Start State' steps first." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required before running this script. Follow the root README first." >&2
  exit 1
fi

brew install gh mas ripgrep wget
brew install --cask codex codexbar

bare=(git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")
"${bare[@]}" pull --ff-only

echo "Agent dependencies are installed."
echo "Now sign in to an agent app, then give it: $HOME/.config/sync/README.md"
