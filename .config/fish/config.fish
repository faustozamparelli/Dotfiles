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
alias c code

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
    read -P "Subject (default: 'changes'): " subject
    if test -z "$subject"
        set subject "changes"
    end
    read -P "Description (optional, press enter to skip): " description
    
    bare add -u
    if test -z "$description"
        bare commit -m "$subject"
    else
        bare commit -m "$subject" -m "$description"
    end
    bare push
end

