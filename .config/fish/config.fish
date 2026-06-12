set -gx HOME_BREW /opt/homebrew
set -gx PATH \
	$HOME_BREW/bin \
	$HOME_BREW/sbin \
	$PATH
set -gx PATH /Users/faustozamparelli/.local/bin $PATH
test -f ~/.config/fish/secrets.fish; and source ~/.config/fish/secrets.fish
alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

set -gx THEME dark
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
function c
    set -l target

    if test (count $argv) -eq 0
        set target .
    else
        set target $argv[1]
    end

    if test -d "$target"
        env -u VIRTUAL_ENV -u VIRTUAL_ENV_PROMPT code -r "$target"
    else
        env -u VIRTUAL_ENV -u VIRTUAL_ENV_PROMPT code "$argv"
    end
end
alias m micro


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
