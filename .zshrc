export HOMEBREW_PREFIX="/opt/homebrew"

typeset -gU path
path=("$HOME/.local/bin" "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "${path[@]}")
export PATH

# Keep terminal applications such as Codex in color mode.
unset NO_COLOR

export EDITOR="/usr/bin/nano"
export VISUAL="/usr/bin/nano"

# zoxide
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

alias bare='/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME'

alias nb='jupyter lab'

alias l='eza -a --git'
alias ls='l'

alias o='open'

alias py='python3'

alias b='bat'
alias cl='clear'
