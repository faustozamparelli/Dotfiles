if status is-interactive
  set fish_greeting ""

  #Set VIM as the default editor + alias
  set -gx EDITOR nvim
  alias n nvim
  alias nh 'NVIM_APPNAME=nvimheavy nvim'
  alias nn nvim_configuration_swticher.sh 

  #thefuck
  thefuck --alias | source 

  set -gx PYENV_ROOT "$HOME/.pyenv"
  # Environment Variables
  set -gx PIPENV_PYTHON "$PYENV_ROOT/shims/python"
  set -gx JAVA_HOME /opt/homebrew/opt/openjdk
  set -gx GOKU_EDN_CONFIG_FILE ~/.config/goku/karabiner.edn
  set -Ux PIP_NO_CACHE_DIR true

  set -x PNPM_HOME "/Users/faustozamparelli/Library/pnpm"
  set -x PATH $PNPM_HOME $PATH

  # Add directories to PATH
  set -Ua fish_user_paths /opt/homebrew/bin
  set -Ua fish_user_paths $PYENV_ROOT/bin
  set -Ua fish_user_paths $JAVA_HOME/bin
  set -Ua fish_user_paths /opt/homebrew/opt/openvpn/sbin
  set -Ua fish_user_paths /usr/local/bin/
  set -Ua fish_user_paths /usr/local/bin/
  source /opt/homebrew/opt/asdf/libexec/asdf.fish

  #Adding texlive to path for vscode latex workshop
  set -gx PATH $PATH /opt/homebrew/opt/texlive/bin

  #Api keys
  set -Ux GROQ_API_KEY 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

  #Adding the bare directory for my dotfiles
  alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

  # Pyenv Initialization
  pyenv init - | source

  #fifc
  set -Ux fifc_editor nvim
  set -U fifc_fd_opts --hidden

  function z_tmux
      __zoxide_z $argv
  end

  # Aliases
  alias dev 'open http://localhost:3000; npm run dev'
  alias g++ "g++-14"
  alias gcc "gcc-14"

  alias g git
  alias lg lazygit
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
  alias fi "yazi"
  alias ts "ts-node"
  alias t "taskwarrior-tui"

  function server
      set current_dir (pwd)
      if test (count $argv) -gt 0
          set start_file $argv[1]
      else
          set start_file ""
      end
      live-server --mount=/:"$current_dir" "$start_file"
  end

  #setting up the ssh
  alias mcstudio 'ssh -i ~/.ssh/mcpro faustozamparelli@192.168.1.123 -t "/opt/homebrew/bin/fish"'
  alias mcpro 'ssh -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216 -t "/opt/homebrew/bin/fish"'

  function cpmcstudio
    scp -i ~/.ssh/mcpro faustozamparelli@192.168.1.123:$argv[1] $argv[2]
  end

  function cpmcpro
    scp -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216:$argv[1] $argv[2]
  end
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

  # for yazi
  function yy
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		cd -- "$cwd"
	end
	rm -f -- "$tmp"
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
    bind \ed '/opt/homebrew/bin/bash ~/.config/tmux/tmux-dp1.sh'
    bind \ef '/opt/homebrew/bin/bash ~/.config/tmux/tmux-recursive.sh'

    bind \ej '~/.config/tmux/tmux-layouts.sh'
    #bind \ee 'nvim'
  end

  # Set up SSH agent to authenticate to GitHub
    eval (ssh-agent -c) &>/dev/null
    switch (hostname)
        case "faustozamparelli"
            ssh-add ~/.ssh/mcstudio &>/dev/null
        case "Faustos-MacBook-Pro.local"
            ssh-add ~/.ssh/mcpro &>/dev/null
        case '*'
            echo "Unknown machine"
    end

  # open tmux at login, but not in VS Code
    if not set -q TMUX
      if test "$TERM_PROGRAM" != "vscode"
          exec tmux -f ~/.config/tmux/tmux.conf new-session -A -s fish
          #renaming tmux window
          function cd
              builtin cd $argv; and tmux rename-window (basename $PWD)
          end

          function z_tmux
              __zoxide_z $argv; and tmux rename-window (basename $PWD)
          end
      end
    end
end
