#!/opt/homebrew/bin/fish

function brew_sync
    # Set the sync flag (exported so the brew function can check it)
    set -gx BREW_SYNC_RUNNING 1

    # Define directories and files
    set BREW_DIR ~/.config/brew
    set BREW_LEAVES $BREW_DIR/brew-leaves.txt
    set BREW_TAPS $BREW_DIR/brew-taps.txt

    # Check prerequisites
    if not test -d $BREW_DIR
        echo "❌ Brew config directory missing!"
        return 1
    end

    if not type -q brew
        echo "❌ Install Homebrew first!"
        return 1
    end

    # Get current installed formulae and tracked packages
    set local_formulae (brew leaves)
    set github_pkgs (cat $BREW_LEAVES)

    # Identify extra packages (installed but not tracked)
    set extra_pkgs
    for pkg in $local_formulae
        if not contains $pkg $github_pkgs
            set extra_pkgs $extra_pkgs $pkg
        end
    end

    # Prompt and uninstall extra packages if any found
    if test (count $extra_pkgs) -gt 0
        echo "🚨 Extra packages found:"
        for pkg in $extra_pkgs
            echo $pkg
        end
        read -q CONFIRM "Uninstall these? [y/N] "
        echo ""
        if test $CONFIRM = "y"
            echo "\n🗑️ Uninstalling extras..."
            for pkg in $extra_pkgs
                echo "📦 Removing package: $pkg"
                brew uninstall --force $pkg
            end
        end
    end

    # Sync taps
    echo "\n🔄 Syncing taps..."
    cat $BREW_TAPS | xargs -I{} brew tap {}

    # Sync main packages from the tracked leaves
    echo "\n🔄 Syncing main packages..."
    for pkg in (cat $BREW_LEAVES)
        if contains $pkg $local_formulae
            # Check if package is outdated
            set outdated_count (brew outdated | grep -cxF $pkg)
            if test $outdated_count -gt 0
                echo "\n📦 Upgrading existing package: $pkg"
                brew upgrade $pkg
            else
                echo "✅ Already up-to-date: $pkg"
            end
        else
            echo "\n📦 Installing new package: $pkg"
            set -lx HOMEBREW_NO_AUTO_UPDATE 1
            brew install $pkg
        end
    end

    # Cleanup: unset the sync flag
    set -e BREW_SYNC_RUNNING

    echo "\n🎉 Homebrew synchronization complete!"
end
