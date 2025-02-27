if [[ $- == *i* ]]; then
  export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
  # Make zsh prompt minimal
  export PROMPT="%~ %# "
  # nvim default
  export EDITOR=nvim

  # Load oh-my-zsh plugins
  export ZSH="/Users/$(whoami)/.oh-my-zsh"
  export PATH="/opt/homebrew/bin:$PATH"
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  plugins=(git)
  source $ZSH/oh-my-zsh.sh

  # Sync brew packages after pulling from GitHub
  source ~/.config/brew/brew-sync.sh

  # Environment Variables
  export ZSH="$HOME/.oh-my-zsh"
  export JAVA_HOME="/opt/homebrew/opt/openjdk"
  export GOKU_EDN_CONFIG_FILE="$HOME/.config/goku/karabiner.edn"
  export PIP_NO_CACHE_DIR=true
  export PNPM_HOME="$HOME/Library/pnpm"
  export C_INCLUDE_PATH="/opt/homebrew/include"
  export CPLUS_INCLUDE_PATH="/opt/homebrew/include"

  # Add directories to PATH
  export PATH="$HOME/.emacs.d/bin:$PATH"
  export PATH="/opt/homebrew/opt/openvpn/sbin:$PATH"
  export PATH="/usr/local/bin:$PATH"
  export PATH="$JAVA_HOME/bin:$PATH"
  export PATH="$PNPM_HOME:$PATH"
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
  # Texlive to PATH for VS Code LaTeX workshop
  export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

  # Aliases
  alias emacs="emacsclient -n"
  alias dev="open http://localhost:3000; npm run dev"
  alias gcc="gcc-14"
  alias g++="g++-14"
  export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
  alias g="git"
  alias lg="lazygit"
  alias glg="tig"
  alias tk="tmux kill-server"
  alias jp="jupyter notebook"
  alias o="open"
  alias python="python3"
  alias py="python"
  alias cat="bat"
  alias b="bat"
  alias cl="clear"
  alias del="trash_move.sh"
  alias delx="trash_empty.sh"
  alias c="cd"
  alias e="exit"
  alias ts="ts-node"
  alias n="nvim"
  alias t="taskwarrior-tui"
  alias code="code -r"
  alias qalc="qalc -s 'angle 2'"
  alias bare="/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"


  # Make brew tracking automated
  brew() {
      command brew "$@"
      # Run brew-tracker.sh only for commands that change installed packages,
      # but not for upgrade/update commands.
      if [[ "$1" == "install" || "$1" == "uninstall" || "$1" == "tap" || "$1" == "untap" ]]; then
          ~/.config/brew/brew-tracker.sh
      fi
      # Only run brew-sync.sh if we're not in the middle of an upgrade/update
      if [[ "$1" != "upgrade" && "$1" != "update" && -z "$BREW_SYNC_RUNNING" ]]; then
          ~/.config/brew/brew-sync.sh
      fi
  }

  # use fuck as an alias 
  eval "$(thefuck --alias)"
  
  eval "$(zoxide init zsh)"

  # Bat theme
  export BAT_THEME="Dracula"

  # For yazi
  yy() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    local cwd
    cwd="$(cat -- "$tmp")"
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
    rm -f -- "$tmp"
  }

  # eza (ll / lla)
  if command -v eza &>/dev/null; then
    alias l='eza --color=always --long -a --git --no-filesize --icons=always --no-time --no-user --no-permissions --grid'
    alias ls='l'
    alias la='eza --long --total-size -a --no-time --no-user --no-permissions'
    alias lt='tre'
  fi

  # fzf key bindings: override default Ctrl-R binding from oh-my-zsh
  if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS="--bind 'enter:execute($EDITOR {})'"
    fzf-history-widget() {
      local selected
      selected=$(fc -rl 1 | fzf --height 40% --reverse --query="$LBUFFER") && LBUFFER="$selected"
      CURSOR=$#LBUFFER
      zle reset-prompt
    }
    zle -N fzf-history-widget
    bindkey '^R' fzf-history-widget
  fi
fi
