export HOMEBREW_PREFIX="/opt/homebrew"

export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Keep terminal applications such as Codex in color mode.
unset NO_COLOR

# Theme placeholder (kept for parity, unused in Zsh)
export THEME="dark"


# zoxide
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

alias bare='/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME'

alias nb='jupyter-notebook'

alias l='eza -a --git'
alias ls='l'
alias lg='lazygit'

alias o='open'

alias python='uv run python'
alias py='python'

alias b='bat'
alias cl='clear'
alias fi='yazi'
alias c='code -r'
