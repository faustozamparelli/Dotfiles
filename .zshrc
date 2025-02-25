if [[ $- == *i* ]]; then
  # Load oh-my-zsh plugins
  export PATH="/opt/homebrew/bin:$PATH"
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  plugins=(git)
  source ~/.oh-my-zsh/oh-my-zsh.sh

  # Sync brew packages after pulling from GitHub
  source ~/.config/brew/brew-sync.sh

  # Make zsh prompt minimal
  export PROMPT='%~ %# '
  # nvim default
  export EDITOR=nvim

  # Environment Variables
  export ZSH="$HOME/.oh-my-zsh"
  export JAVA_HOME="/opt/homebrew/opt/openjdk"
  export GOKU_EDN_CONFIG_FILE="$HOME/.config/goku/karabiner.edn"
  export PIP_NO_CACHE_DIR=true
  export PNPM_HOME="$HOME/Library/pnpm"
  export C_INCLUDE_PATH="/opt/homebrew/include"
  export CPLUS_INCLUDE_PATH="/opt/homebrew/include"

  # Add directories to PATH
  export PATH="/opt/homebrew/opt/openvpn/sbin:$PATH"
  export PATH="/usr/local/bin:$PATH"
  export PATH="$JAVA_HOME/bin:$PATH"
  export PATH="$PNPM_HOME:$PATH"
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
  # Texlive to PATH for VS Code LaTeX workshop
  export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"


  # Aliases
  alias dev='open http://localhost:3000; npm run dev'
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
  alias z="z_tmux"
  alias e="exit"
  alias fi="yazi"
  alias ts="ts-node"
  alias t="taskwarrior-tui"
  alias code="code -r"
  alias qalc="qalc -s 'angle 2'"
  alias bare='/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME'


  # Make brew tracking automated
  brew() {
      command brew "$@"
      if [[ "$1" == "install" || "$1" == "uninstall" || "$1" == "tap" || "$1" == "untap" || "$1" == "upgrade" ]]; then
          ~/.config/brew/brew-tracker.sh
      fi
      if [[ -z "$BREW_SYNC_RUNNING" ]]; then
          ~/.config/brew/sync-brew.sh
      fi
  }

  # Enhanced cd function with tmux renaming
  cd() {
    builtin cd "$@" || return
    if [[ -n "$TMUX" ]]; then
      tmux rename-window "$(basename "$PWD")"
    fi
  }

  z_tmux() {
    z "$@" || return
    if [[ -n "$TMUX" ]]; then
      tmux rename-window "$(basename "$PWD")"
    fi
  }

  zn() {
    z "$@" || { echo "Directory not found!"; return; }
    [[ -n "$TMUX" ]] && tmux rename-window "$(basename "$PWD")"
    nvim .
  }

  n() {
    if [[ "$1" == "." ]]; then
      nvim .
    else
      [[ -n "$TMUX" ]] && tmux rename-window "$(basename -- "$1")"
      nvim "$@"
    fi
  }

  curljq() {
    local curl_args=() jq_args=()
    local split=false
    for arg in "$@"; do
      if [[ "$arg" == "--" ]]; then
        split=true
        continue
      fi
      if $split; then
        jq_args+=("$arg")
      else
        curl_args+=("$arg")
      fi
    done
    /usr/bin/curl -s "${curl_args[@]}" | jq "${jq_args[@]}"
  }
  alias curl='curljq'


  # use fuck as an alias 
  eval "$(thefuck --alias)"

  server() {
    local current_dir
    current_dir="$(pwd)"
    local start_file="${1:-}"
    live-server --mount=/:"$current_dir" "$start_file"
  }

  # SSH setup
  alias mcstudio='ssh -i ~/.ssh/mcpro faustozamparelli@192.168.1.123 -t "/opt/homebrew/bin/fish"'
  alias mcpro='ssh -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216 -t "/opt/homebrew/bin/fish"'

  cpmcstudio() {
    scp -i ~/.ssh/mcpro faustozamparelli@192.168.1.123:"$1" "$2"
  }

  cpmcpro() {
    scp -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216:"$1" "$2"
  }

  # Bat theme
  export BAT_THEME="Dracula"

  # Git clone shortcut
  gcl() {
    local repo_url="https://github.com/$1"
    if [[ -n "$2" ]]; then
      git clone "$repo_url" "$2"
    else
      git clone "$repo_url"
    fi
  }

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

  # Set up SSH agent to authenticate to GitHub
  eval "$(ssh-agent -c)" &>/dev/null
  case "$(hostname)" in
    "faustozamparelli") ssh-add ~/.ssh/mcstudio &>/dev/null ;;
    "Faustos-MacBook-Pro.local") ssh-add ~/.ssh/mcpro &>/dev/null ;;
    *) echo "Unknown machine" ;;
  esac

  export PATH="$HOME/.emacs.d/bin:$PATH"
  alias emacs="emacsclient -n"
fi
