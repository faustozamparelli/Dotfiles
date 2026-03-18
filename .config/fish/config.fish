set -gx HOME_BREW /opt/homebrew
set -gx PATH \
	$HOME_BREW/bin \
	$HOME_BREW/sbin \
	$HOME/.virtualenvs/ml/bin \
	$PATH
source (brew --prefix asdf)/libexec/asdf.fish
alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

set -gx THEME dark
set fish_greeting ""
set -g pure_enable_git true

#zoxide setup
if type -q zoxide
        zoxide init fish | source
end


alias n nvim
alias jp "jupyter notebook"
alias l "eza -a --git"
alias lg "lazygit"
alias o open
alias py python
alias b bat
alias cl clear
alias fi yazi
alias c code

