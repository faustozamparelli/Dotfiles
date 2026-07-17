set -gx HOME_BREW /opt/homebrew
set -gx PATH \
	$HOME_BREW/bin \
	$HOME_BREW/sbin \
	$PATH
set -gx PATH /Users/faustozamparelli/.local/bin $PATH
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

alias nb "jupyter notebook"
alias l "eza -a --git"
alias ls l
alias o open
alias python "uv run python"
alias py python
alias b bat
alias cl clear
alias fi yazi
alias sv "source .venv/bin/activate.fish"
alias n nvim
alias keymap-docs "$HOME/.config/keymaps/keymap-docs"

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

# Ghostty starts in one predictable tmux workspace. Nested shells and other
# terminals remain untouched.
if status is-interactive; and test "$TERM_PROGRAM" = ghostty; and not set -q TMUX; and not set -q FAUSTO_NO_TMUX
    exec tmux new-session -A -s default
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
