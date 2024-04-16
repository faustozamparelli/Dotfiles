if status is-interactive
  set fish_greeting ""

  #Set VIM as the default editor + alias
  set -gx EDITOR nvim
  alias n nvim

  #thefuck
  thefuck --alias | source 

  # Environment Variables
  set -gx PYENV_ROOT "$HOME/.pyenv"
  set -gx PIPENV_PYTHON "$PYENV_ROOT/shims/python"
  set -gx JAVA_HOME /opt/homebrew/opt/openjdk
  set -gx GOKU_EDN_CONFIG_FILE ~/.config/goku/karabiner.edn

  # Add directories to PATH
  set -Ua fish_user_paths /opt/homebrew/bin
  set -Ua fish_user_paths $PYENV_ROOT/bin
  set -Ua fish_user_paths $JAVA_HOME/bin
  set -Ua fish_user_paths /opt/homebrew/opt/openvpn/sbin

  #Add exec to path
  set -Ux fish_user_paths $HOME/dotfiles/.config/bin $fish_user_paths

  #Adding texlive to path for vscode latex workshop
  set -gx PATH $PATH /opt/homebrew/opt/texlive/bin

  #Adding the bare directory for my dotfiles
  alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

  # Pyenv Initialization
  pyenv init - | source

  fzf_configure_bindings --directory=\cf --git_status=\cgs --git_log=\cgl --variables= --processes=
  set fzf_directory_opts --bind "enter:execute($EDITOR {} &> /dev/tty)"
  set fzf_fd_opts --hidden 

  # Aliases
  alias g++ "g++-13 -std=c++2a"
  alias gcc "gcc-13 -std=c17"

  alias ghe "gh copilot explain"
  alias ghs "gh copilot suggest"

  alias g git
  alias glg "tig"
  alias tk "tmux kill-server"
  alias jp "jupyter notebook"
  alias man tldr
  alias o open
  alias py "python3"

  #set git clone
  function gcl
    set repo_url "https://github.com/$argv[1]"
    set destination $argv[2]
    if test -n "$destination"
        git clone $repo_url $destination
    else
        git clone $repo_url
    end
  end

  #eza (ll / lla)
  if type -q eza
    alias l "eza -l -g --icons"
    alias la "l -a"
    alias lt "la -T -L=2"
  end

  # open tmux at login, but not in VS Code
  if not set -q TMUX
    if test "$TERM_PROGRAM" != "vscode"
      exec tmux -f ~/.config/tmux/tmux.conf new-session -A -s fish
    end
  end
end
