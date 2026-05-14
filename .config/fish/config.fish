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

function gcp --description "Commit all changes and push (prompted message, default: 'changes')"
    read -P "Commit message (default: 'changes'): " message
    if test -z "$message"
        set message "changes"
    end
    git add -A
    git commit -m "$message"
    git push
end

function bcp --description "Bare add -u, commit, and push (prompted message, default: 'changes')"
    read -P "Commit message (default: 'changes'): " message
    if test -z "$message"
        set message "changes"
    end
    bare add -u
    bare commit -m "$message"
    bare push
end

