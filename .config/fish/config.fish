if status is-interactive
  set fish_greeting ""

  #Set VIM as the default editor + alias
  set -gx EDITOR nvim
  alias n nvim

  #thefuck
  thefuck --alias | source 

  set -gx PYENV_ROOT "$HOME/.pyenv"
  # Environment Variables
  set -gx PIPENV_PYTHON "$PYENV_ROOT/shims/python"
  set -gx JAVA_HOME /opt/homebrew/opt/openjdk
  set -gx GOKU_EDN_CONFIG_FILE ~/.config/goku/karabiner.edn

  set -x PNPM_HOME "/Users/faustozamparelli/Library/pnpm"
  set -x PATH $PNPM_HOME $PATH

  # Add directories to PATH
  set -Ua fish_user_paths /opt/homebrew/bin
  set -Ua fish_user_paths $PYENV_ROOT/bin
  set -Ua fish_user_paths $JAVA_HOME/bin
  set -Ua fish_user_paths /opt/homebrew/opt/openvpn/sbin
  set -Ua fish_user_paths /usr/local/bin/

  #Adding texlive to path for vscode latex workshop
  set -gx PATH $PATH /opt/homebrew/opt/texlive/bin

  #Adding the bare directory for my dotfiles
  alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

  # Pyenv Initialization
  pyenv init - | source

  #fifc
  set -Ux fifc_editor nvim
  set -U fifc_fd_opts --hidden

  #renaming tmux window
  function cd
    builtin cd $argv; and tmux rename-window (basename $PWD)
  end

  function z_tmux
    __zoxide_z $argv; and tmux rename-window (basename $PWD)
  end

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
  # alias o "code -r" 
  alias o "open"
  alias py "python3"
  alias cat "bat"
  alias b "bat"
  alias cl "clear"
  alias del "trash_move.sh"
  alias delx "trash_empty.sh"
  alias c "cd"
  alias z "z_tmux"
  alias e "exit"
  alias finder "yazi"
  alias t "ts-node"

  #setting up the ssh
  alias mcstudio 'ssh -i ~/.ssh/key1-mcstudio faustozamparelli@192.168.1.123 -t "/opt/homebrew/bin/fish"'

  #bat theme
  set -gx BAT_THEME "Dracula"

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
    alias l "eza --color=always --long -a --git --no-filesize --icons=always --no-time --no-user --no-permissions"
    alias ls "l"
    alias la "eza --long --total-size -a --no-time --no-user --no-permissions"
    # alias lt "eza --color=always --long -a --git --header --tree --icons=always --no-time --no-user --no-permissions"
     alias lt "tre"
  end

  # fzf.fish
  fzf_configure_bindings  --git_status=\cgs --git_log=\cgl --variables=\cv --processes=\cp --directory=\cs
  set fzf_directory_opts --bind "enter:execute($EDITOR {} &> /dev/tty)"
  set fzf_fd_opts --hidden --type=f
  set fzf_git_status_opts --bind "enter:execute(git diff {})"
  set fzf_git_log_opts --bind "enter:execute(git show {})"
  set fzf_variables_opts --bind "enter:execute(set -gx {} (cat {}))"
  set fzf_processes_opts --bind "enter:execute(kill -9 {})"

  function fish_user_key_bindings
    # Bind Ctrl + f to run the tmux-sessionizer.sh script
    bind \ef '/opt/homebrew/bin/bash ~/.config/tmux/tmux-dp1.sh'
    bind \ed '/opt/homebrew/bin/bash ~/.config/tmux/tmux-recursive.sh'

    bind \ej '~/.config/tmux/tmux-layouts.sh
'
  end


  # open tmux at login, but not in VS Code
    if not set -q TMUX
      if test "$TERM_PROGRAM" != "vscode"
          if set -q SSH_CLIENT
              eval (ssh-agent -c)
              ssh-add ~/.ssh/github
          end
          exec tmux -f ~/.config/tmux/tmux.conf new-session -A -s fish
      end
    end
end
