#!/opt/homebrew/bin/fish

# Ensure a flag argument (0 or 1) is provided
if test (count $argv) -ne 1
    echo "Usage: brew_sync.fish <flag: 0 to push, 1 to sync>"
    exit 1
end

set flag $argv[1]
set BREW_DIR ~/.config/brew
set BREW_LEAVES $BREW_DIR/brew-leaves.txt
set BREW_TAPS $BREW_DIR/brew-taps.txt

if test $flag -eq 0
    # MODE 0: Update local config files and push them to GitHub

    # Update the brew leaves and taps files
    brew leaves > $BREW_LEAVES
    brew tap > $BREW_TAPS

    # Construct commit message with current date
    set commit_msg "Updated brew leaves & taps on " (date)

    # Add, commit, and push changes using your dotfiles git repository
    /opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME add $BREW_LEAVES $BREW_TAPS
    /opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME commit -m "$commit_msg"
    /opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME push origin main

else if test $flag -eq 1
    # MODE 1: Sync local installation with the configuration stored on GitHub

    # First, pull the latest configuration files from GitHub
    /opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME pull origin main

    # Read the remote configuration files
    if test -f $BREW_LEAVES
        set remote_leaves (cat $BREW_LEAVES)
    else
        echo "Error: Remote brew leaves file not found: $BREW_LEAVES"
        set remote_leaves
    end

    if test -f $BREW_TAPS
        set remote_taps (cat $BREW_TAPS)
    else
        echo "Error: Remote brew taps file not found: $BREW_TAPS"
        set remote_taps
    end

    # Get the currently installed brew leaves and taps
    set local_leaves (brew leaves)
    set local_taps (brew tap)

    # For brew leaves (formulae):
    # Install any package listed in the remote file that is missing locally…
    for pkg in $remote_leaves
        if not contains $pkg $local_leaves
            echo "Installing missing brew package: $pkg"
            brew install $pkg
        end
    end

    # …and uninstall any extra package that is installed locally but not in the remote file.
    for pkg in $local_leaves
        if not contains $pkg $remote_leaves
            echo "Uninstalling extra brew package: $pkg"
            brew uninstall $pkg
        end
    end

    # For brew taps:
    # Tap any remote tap that is not present locally…
    for tap in $remote_taps
        if not contains $tap $local_taps
            echo "Tapping missing brew tap: $tap"
            brew tap $tap
        end
    end

    # …and untap any local tap that is not listed in the remote configuration.
    for tap in $local_taps
        if not contains $tap $remote_taps
            echo "Untapping extra brew tap: $tap"
            brew untap $tap
        end
    end

else
    echo "Invalid flag. Use 0 to push configuration or 1 to sync installation with GitHub configuration."
    exit 1
end
