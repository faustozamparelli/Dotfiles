#!/bin/zsh

BREW_DIR=~/.config/brew
BREW_LEAVES="$BREW_DIR/brew-leaves.txt"
BREW_TAPS="$BREW_DIR/brew-taps.txt"

# Update leaves and taps
brew leaves > "$BREW_LEAVES"
brew tap > "$BREW_TAPS"

# Commit and push changes using the full git command
/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME add "$BREW_LEAVES" "$BREW_TAPS"
/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME commit -m "Updated brew leaves & taps on $(date)"
/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME push origin main
