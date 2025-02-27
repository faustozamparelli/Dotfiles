#!/usr/bin/env fish

# Set variables
set BREW_DIR $HOME/.config/brew
set BREW_LEAVES "$BREW_DIR/brew-leaves.txt"
set BREW_TAPS "$BREW_DIR/brew-taps.txt"

# Helper function to check for membership
function contains_item --argument item list...
    for x in $list
        if test "$x" = "$item"
            return 0
        end
    end
    return 1
end

# Define the brew_sync function
function brew_sync
    set -x BREW_SYNC_RUNNING 1

    if not test -d $BREW_DIR
        echo "❌ Brew config directory missing!"
        return 1
    end
    if not type -q brew
        echo "❌ Install Homebrew first!"
        return 1
    end

    set local_formulae (brew leaves | string split "\n")
    set local_casks (brew list --cask | string split "\n")
    set github_pkgs (cat $BREW_LEAVES | string split "\n")
    set all_local $local_formulae $local_casks

    set extra_pkgs
    for pkg in $all_local
        if test -n "$pkg"
            if not contains_item $pkg $github_pkgs
                set extra_pkgs $extra_pkgs $pkg
            end
        end
    end

    if test (count $extra_pkgs) -gt 0
        echo "🚨 Extra packages found:"
        for pkg in $extra_pkgs
            echo $pkg
        end
        read -P "Uninstall these? [y/N] " CONFIRM
        if test "$CONFIRM" = "y"
            echo "🗑️ Uninstalling extras..."
            for pkg in $extra_pkgs
                if contains_item $pkg $local_formulae
                    echo "📦 Removing formula: $pkg"
                    brew uninstall --force $pkg
                else if contains_item $pkg $local_casks
                    echo "📦 Removing cask: $pkg"
                    brew uninstall --cask --force $pkg
                end
            end
        end
    end

    echo "🔄 Syncing taps..."
    for tap in (cat $BREW_TAPS | string split "\n")
        if test -n "$tap"
            brew tap $tap
        end
    end

    echo "🔄 Syncing main packages..."
    for pkg in (cat $BREW_LEAVES | string split "\n")
        if test -n "$pkg"
            if contains_item $pkg $local_formulae -o contains_item $pkg $local_casks
                set outdated_count (brew outdated | grep -cxF $pkg)
                if test $outdated_count -gt 0
                    echo "📦 Upgrading existing package: $pkg"
                    brew upgrade $pkg
                else
                    echo "✅ Already up-to-date: $pkg"
                end
            else
                echo "📦 Installing new package: $pkg"
                set -lx HOMEBREW_NO_AUTO_UPDATE 1
                set -lx HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK 1
                set -lx HOMEBREW_NO_ENV_HINTS 1
                if not brew install $pkg 2>/dev/null
                    echo "🔄 Trying cask install..."
                    set -lx HOMEBREW_NO_AUTO_UPDATE 1
                    set -lx HOMEBREW_NO_ENV_HINTS 1
                    brew install --cask $pkg
                end
            end
        end
    end

    set -e BREW_SYNC_RUNNING
    echo "🎉 Homebrew synchronization complete!"
end
