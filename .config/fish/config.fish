set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx PNPM_HOME $HOME/Library/pnpm

# Keep one deterministic toolchain path on both Macs. fish_add_path normalizes
# paths and prevents the duplicate Homebrew entries produced by editing PATH.
set -g fish_user_paths
fish_add_path -g \
    $HOME/.local/toolchains/bin \
    $HOME/.local/bin \
    $PNPM_HOME/bin \
    $HOMEBREW_PREFIX/opt/python/libexec/bin \
    $HOMEBREW_PREFIX/bin \
    $HOMEBREW_PREFIX/sbin

# mac-sync maintains stable gcc/g++ links across Homebrew major upgrades.
if test -x $HOME/.local/toolchains/bin/gcc
    set -gx CC $HOME/.local/toolchains/bin/gcc
end
if test -x $HOME/.local/toolchains/bin/g++
    set -gx CXX $HOME/.local/toolchains/bin/g++
end
test -f ~/.config/fish/secrets.fish; and source ~/.config/fish/secrets.fish
alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

set -gx THEME dark
set -gx EDITOR nvim
set -gx VISUAL nvim
set fish_greeting ""
set -g pure_enable_git true

#zoxide setup
if type -q zoxide
        zoxide init fish | source
end

alias nb "jupyter lab"
alias l "eza -a --git"
alias ls l
alias o open
alias py python
alias b bat
alias cl clear
alias sv "source .venv/bin/activate.fish"
alias n nvim
alias keymap-docs "$HOME/.config/keymaps/keymap-docs"

function amsc-env --description "Load the manually managed AMSC C++ libraries"
    source "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Cpp/AMSC/env.fish"
end

# Route only the stealth profile through the monochrome presentation wrapper.
# Every other Codex invocation keeps the normal full-color TUI.
function codex
    set -l previous ""
    for arg in $argv
        if test "$arg" = "--profile=stealth"; or test "$previous:$arg" = "--profile:stealth"
            "$HOME/.codex/bin/codex-stealth" $argv
            return $status
        end
        set previous "$arg"
    end
    /opt/homebrew/bin/codex $argv
end


#if pressed just enter the message will be 'changes'
function gcp --description "Commit all changes and push (subject + optional description)"
    read -P "Subject (default: 'changes'): " subject
    if test -z "$subject"
        set subject "changes"
    end
    read -P "Description (optional, press enter to skip): " description
    
    git add -A
    if test -z "$description"
        git commit -m "$subject"
    else
        git commit -m "$subject" -m "$description"
    end
    git push
end

# Ghostty starts in the persistent Herdr workspace. Shells created inside Herdr
# inherit HERDR_ENV and therefore do not recurse.
if status is-interactive; and test "$TERM_PROGRAM" = ghostty; and not set -q HERDR_ENV; and not set -q FAUSTO_NO_HERDR
    exec herdr
end

function bcp --description "Bare add -u, commit, and push (subject + optional description)"
    if type -q sync-maintain
        sync-maintain
    else
        ~/.config/sync/maintain.sh
    end

    set -l sync_status $status
    if test $sync_status -ne 0
        echo "sync-maintain failed; bcp stopped." >&2
        return $sync_status
    end

    bare add -u

    read -P "Subject (default: 'changes'): " subject
    if test -z "$subject"
        set subject "changes"
    end
    read -P "Description (optional, press enter to skip): " description

    if test -z "$description"
        bare commit -m "$subject"
    else
        bare commit -m "$subject" -m "$description"
    end
    bare push
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
