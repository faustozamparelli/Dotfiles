#!/bin/zsh

BREW_DIR="$HOME/.config/brew"
BREW_LEAVES="$BREW_DIR/brew-leaves.txt"
BREW_TAPS="$BREW_DIR/brew-taps.txt"

brew_sync() {
    # Set sync flag immediately
    export BREW_SYNC_RUNNING=1

    # Check prerequisites
    if [[ ! -d "$BREW_DIR" ]]; then
        echo "❌ Brew config directory missing!"
        return 1
    fi
    ! command -v brew &>/dev/null && echo "❌ Install Homebrew first!" && return 1

    # Get current state: only track formula leaves
    local_formulae=(${(f)"$(brew leaves)"})
    github_pkgs=(${(f)"$(<"$BREW_LEAVES")"})

    # Build associative arrays for quick lookup
    declare -A all_local
    for pkg ($local_formulae) all_local[$pkg]=1
    declare -A tracked
    for pkg ($github_pkgs) tracked[$pkg]=1

    # Identify extra packages (only formulae are considered)
    extra_pkgs=()
    for pkg (${(k)all_local}) {
        (( ! tracked[$pkg] )) && extra_pkgs+=($pkg)
    }

    # Prompt and uninstall extra packages if confirmed
    if (( ${#extra_pkgs} > 0 )); then
        echo "🚨 Extra packages found:"
        for pkg in $extra_pkgs; do
            echo "$pkg"
        done
        read -q "CONFIRM?Uninstall these? [y/N] "
        echo ""
        if [[ "$CONFIRM" == "y" ]]; then
            echo "\n🗑️ Uninstalling extras..."
            for pkg ($extra_pkgs) {
                echo "📦 Removing package: $pkg"
                brew uninstall --force "$pkg"
            }
        fi
    fi

    # Sync taps
    echo "\n🔄 Syncing taps..."
    xargs -I{} brew tap {} < "$BREW_TAPS"

    # Sync main packages from brew-leaves
    echo "\n🔄 Syncing main packages..."
    while read -r pkg; do
        if (( $local_formulae[(Ie)$pkg] )); then
            if [[ $(brew outdated | grep -cxF "$pkg") -gt 0 ]]; then
                echo "\n📦 Upgrading existing package: $pkg"
                brew upgrade "$pkg"
            else
                echo "✅ Already up-to-date: $pkg"
            fi
        else
            echo "\n📦 Installing new package: $pkg"
            HOMEBREW_NO_AUTO_UPDATE=1 brew install "$pkg"
        fi
    done < "$BREW_LEAVES"

    # Cleanup after sync completes
    unset BREW_SYNC_RUNNING
    echo "\n🎉 Homebrew synchronization complete!"
}
