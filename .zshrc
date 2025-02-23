if [[ $- == *i* ]]; then


  # Automate brew packages
  export HOMEBREW_INSTALL_HOOK=~/.config/brew/brew-tracker.sh
  export HOMEBREW_UNINSTALL_HOOK=~/.config/brew/brew-tracker.sh

  # Environment Variables
  export ZSH="$HOME/.oh-my-zsh"
  export JAVA_HOME="/opt/homebrew/opt/openjdk"
  export GOKU_EDN_CONFIG_FILE="$HOME/.config/goku/karabiner.edn"
  export PIP_NO_CACHE_DIR=true
  export PNPM_HOME="$HOME/Library/pnpm"

  # Add directories to PATH
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="/opt/homebrew/opt/openvpn/sbin:$PATH"
  export PATH="/usr/local/bin:$PATH"
  export PATH="$JAVA_HOME/bin:$PATH"
  export PATH="$PNPM_HOME:$PATH"

  # Make zsh prompt minimal + ESC for vi mode
  export PROMPT='%~ %# '

  # Needed for zsh plugins
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

  plugins=(git zsh-vi-mode)

  source $ZSH/oh-my-zsh.sh

  # Set VIM as the default editor + alias
  export EDITOR=nvim
  alias nh='NVIM_APPNAME=nvimheavy nvim'
  alias nn='nvim_configuration_swticher.sh'

  # Source asdf if available
  if [ -f "$ASDF_DIR/libexec/asdf.sh" ]; then
    source "$ASDF_DIR/libexec/asdf.sh"
  fi

  # Adding texlive to PATH for VS Code LaTeX workshop
  export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

  # Adding the C and C++ include paths
  export C_INCLUDE_PATH="/opt/homebrew/include"
  export CPLUS_INCLUDE_PATH="/opt/homebrew/include"

  # API keys
  export GROQ_API_KEY="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"

  # Adding the bare directory for my dotfiles
  alias bare='/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME'

  # Thefuck alias
  eval "$(thefuck --alias)"

  # fifc
  export fifc_editor=nvim
  export fifc_fd_opts="--hidden"

  # Enhanced `cd` function with tmux renaming
  function cd() {
    builtin cd "$@" || return
    if [[ -n "$TMUX" ]]; then
      tmux rename-window "$(basename "$PWD")"
    fi
  }

  function z_tmux() {
    z "$@" || return
    if [[ -n "$TMUX" ]]; then
      tmux rename-window "$(basename "$PWD")"
    fi
  }

  function zn() {
    z "$@" || { echo "Directory not found!"; return; }
    [[ -n "$TMUX" ]] && tmux rename-window "$(basename "$PWD")"
    nvim .
  }

  function n() {
    if [[ "$1" == "." ]]; then
      nvim .
    else
      [[ -n "$TMUX" ]] && tmux rename-window "$(basename -- "$1")"
      nvim "$@"
    fi
  }

  function curljq() {
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

  function server() {
    local current_dir
    current_dir="$(pwd)"
    local start_file="${1:-}"
    live-server --mount=/:"$current_dir" "$start_file"
  }

  # SSH setup
  alias mcstudio='ssh -i ~/.ssh/mcpro faustozamparelli@192.168.1.123 -t "/opt/homebrew/bin/fish"'
  alias mcpro='ssh -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216 -t "/opt/homebrew/bin/fish"'

  function cpmcstudio() {
    scp -i ~/.ssh/mcpro faustozamparelli@192.168.1.123:"$1" "$2"
  }

  function cpmcpro() {
    scp -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216:"$1" "$2"
  }

  # Bat theme
  export BAT_THEME="Dracula"

  # Git clone shortcut
  function gcl() {
    local repo_url="https://github.com/$1"
    if [[ -n "$2" ]]; then
      git clone "$repo_url" "$2"
    else
      git clone "$repo_url"
    fi
  }

  # For yazi
  function yy() {
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

  # fzf key bindings
  if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS="--bind 'enter:execute($EDITOR {})'"
  fi

  # Set up SSH agent to authenticate to GitHub
  eval "$(ssh-agent -c)" &>/dev/null
  case "$(hostname)" in
    "faustozamparelli") ssh-add ~/.ssh/mcstudio &>/dev/null ;;
    "Faustos-MacBook-Pro.local") ssh-add ~/.ssh/mcpro &>/dev/null ;;
    *) echo "Unknown machine" ;;
  esac

fi



export PATH="$HOME/.emacs.d/bin:$PATH"

alias emacs="emacsclient -n"


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

