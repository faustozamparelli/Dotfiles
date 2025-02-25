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

    # Get current state
    local_formulae=(${(f)"$(brew leaves)"})
    local_casks=(${(f)"$(brew list --cask)"})
    github_pkgs=(${(f)"$(<"$BREW_LEAVES")"})

    # Find extra packages
    declare -A all_local
    for pkg ($local_formulae $local_casks) all_local[$pkg]=1
    declare -A tracked
    for pkg ($github_pkgs) tracked[$pkg]=1
    
    extra_pkgs=()
    for pkg (${(k)all_local}) {
        (( ! tracked[$pkg] )) && extra_pkgs+=($pkg)
    }

    # Remove extra packages
    if (( ${#extra_pkgs} > 0 )); then
        echo "🚨 Extra packages found:\n${(F)extra_pkgs}"
        read -q "CONFIRM?Uninstall these? [y/N] "
        echo ""
        if [[ "$CONFIRM" == "y" ]]; then
            echo "\n🗑️ Uninstalling extras..."
            for pkg ($extra_pkgs) {
                if (( $local_formulae[(Ie)$pkg] )); then
                    echo "📦 Removing formula: $pkg"
                    brew uninstall --force $pkg
                elif (( $local_casks[(Ie)$pkg] )); then
                    echo "📦 Removing cask: $pkg"
                    brew uninstall --cask --force $pkg
                fi
            }
        fi
    fi

    # Sync taps first
    echo "\n🔄 Syncing taps..."
    cat "$BREW_TAPS" | xargs -I{} brew tap {}

    # Install/update required packages
    echo "\n🔄 Syncing main packages..."
    while read -r pkg; do
        # Check installation status properly across formula/casks
        if (( $local_formulae[(Ie)$pkg] )) || (( $local_casks[(Ie)$pkg] )); then
            if [[ $(brew outdated | grep -cxF "$pkg") -gt 0 ]]; then
                echo "\n📦 Upgrading existing package: $pkg"
                [[ $(type -w "brew upgrade $pkg") == *"--cask"* ]] && \
                    upgrade_flag="--cask" || upgrade_flag=""
                brew upgrade $upgrade_flag "$pkg"
            else
                echo "✅ Already up-to-date: $pkg"
            fi
        else
            echo "\n📦 Installing new package: $pkg"
            # Try installing as formula first
            if ! HOMEBREW_NO_AUTO_UPDATE=1 \
                HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 \
                HOMEBREW_NO_ENV_HINTS=1 \
                brew install "$pkg" 2>/dev/null; then
                
                # Fallback to cask install if formula fails
                echo "🔄 Trying cask install..."
                HOMEBREW_NO_AUTO_UPDATE=1 \
                HOMEBREW_NO_ENV_HINTS=1 \
                brew install --cask "$pkg"
            fi
        fi
    done < "$BREW_LEAVES"

    # Cleanup after sync completes
    unset BREW_SYNC_RUNNING
    
    echo "\n🎉 Homebrew synchronization complete!"
}
