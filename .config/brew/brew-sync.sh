#!/bin/zsh

BREW_DIR="$HOME/.config/brew"
BREW_LEAVES="$BREW_DIR/brew-leaves.txt"
BREW_TAPS="$BREW_DIR/brew-taps.txt"
export BREW_SYNC_RUNNING=1

brew_sync() {
    if [[ ! -d "$BREW_DIR" ]]; then
        echo "❌ Brew config directory not found! Have you cloned your dotfiles?"
        return 1
    fi

    # Ensure Homebrew is installed
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew not found! Please install it first: https://brew.sh"
        return 1
    fi

    echo "🔄 Syncing Homebrew taps..."
    cat "$BREW_TAPS" | xargs -I{} brew tap {}

    echo "🔄 Syncing Homebrew packages..."
    while read -r package; do
      if brew outdated | grep -qx "$package"; then
        echo "📦 Upgrading: $package"
        brew upgrade "$package"
      elif brew list --formula | grep -qx "$package"; then
        echo "✅ Already installed: $package"
      elif brew list --cask | grep -qx "$package"; then
        echo "✅ Already installed (cask): $package"
      elif brew info "$package" &>/dev/null; then
        echo "✅ Already installed (via tap): $package"
      else
        echo "📦 Installing: $package"
        brew install "$package"
      fi
    done < "$BREW_LEAVES"

    echo "🎉 Homebrew sync complete!"
}
