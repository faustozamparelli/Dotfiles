# ============================
# Core: Homebrew + PATH setup
# ============================
set -gx HOME_BREW /opt/homebrew

set -gx JAVA_HOME $HOME_BREW/opt/openjdk
set -gx PNPM_HOME "$HOME/Library/pnpm"

set -gx PATH \
    $HOME_BREW/bin \
    $HOME_BREW/sbin \
    $HOME/.virtualenvs/ml/bin \
    $PATH

source (brew --prefix asdf)/libexec/asdf.fish

set -gx PATH $JAVA_HOME/bin /opt/homebrew/opt/openvpn/sbin $PATH

set -gx MANPATH $HOME_BREW/share/man $MANPATH
set -gx MANPATH ~/man-pages $MANPATH 
set -gx PATH /Applications/MATLAB_R2025b.app/bin $PATH

if test -z "$ASDF_DATA_DIR"
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

if test -d $_asdf_shims
    contains $_asdf_shims $PATH; or set -gx PATH $_asdf_shims $PATH
end
set --erase _asdf_shims

contains $PNPM_HOME $PATH; or set -gx PATH $PNPM_HOME $PATH

#set -gx PATH $PATH $HOME/Library/TinyTeX/bin/universal-darwin

set -gx C_INCLUDE_PATH $HOME_BREW/include
set -gx CPLUS_INCLUDE_PATH $HOME_BREW/include

# ============================
# Shell basics
# ============================
set fish_greeting ""
fish_vi_key_bindings
set -gx EDITOR nvim
set pure_enable_single_line_prompt true

alias nh 'NVIM_APPNAME=nvimheavy nvim'
alias nn nvim_configuration_swticher.sh

if type -q thefuck
    thefuck --alias | source
end

# ============================
# ZOXIDE (CRITICAL SECTION)
# ============================
if status is-interactive
    if type -q zoxide
        zoxide init fish | source

        # capture the real zoxide `z` ONCE
        if functions -q z
            functions -c z __zoxide_public
        end
    end
end

# ============================
# fifc
# ============================
set -Ux fifc_editor nvim
set -U fifc_fd_opts --hidden

# ============================
# Theme
# ============================
if test (osascript -e 'tell app "System Events" to tell appearance preferences to get dark mode') = "true"
    set -gx THEME dark
    set -gx BAT_THEME Dracula
else
    set -gx THEME light
end

# ============================
# Navigation helpers
# ============================
function f
    if test (count $argv) -eq 0
        cd (fd --type directory --no-ignore | fzf)
    else
        cd $argv
    end
end

# ============================
# Aliases
# ============================
alias lg lazygit
alias glog "git lg"
alias glg tig

alias tk "tmux kill-server"
alias jp "jupyter notebook"
alias o open
alias py python
alias cat bat
alias b bat
alias cl clear
alias del trash_move.sh
alias delx trash_empty.sh
alias c cd
alias e exit
alias fi yazi
alias ts ts-node
alias t taskwarrior-tui
alias cursor "cursor -r"
alias study "py $HOME/Documents/Developer/StudyTracker/study.py"

alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

# ============================
# Functions
# ============================

function cd
    builtin cd $argv
    if set -q TMUX; and tmux has-session >/dev/null 2>&1
        tmux rename-window (basename $PWD)
    end
end

# tmux-aware zoxide wrapper
function z_tmux
    __zoxide_public $argv
    if test $status -eq 0; and set -q TMUX; and tmux has-session >/dev/null 2>&1
        tmux rename-window (basename $PWD)
    end
end

# replace z cleanly
if functions -q z
    functions -e z
end
function z --description "zoxide + tmux rename"
    z_tmux $argv
end

function zn
    z $argv
    if test $status -eq 0
        n .
    else
        echo "Directory not found!"
    end
end

function n
    if test (count $argv) -gt 0 -a "$argv[1]" != "."
        set -q TMUX; and tmux rename-window (basename -- $argv[1])
        nvim $argv
    else
        nvim .
    end
end

function gsp
    git status -s --porcelain
end

function gcp
    git pull --ff-only
    set default_msg (git status -s --porcelain)
    read -P "Commit message (leave blank to use status summary): " msg
    test -z "$msg"; and set msg $default_msg
    git add .
    git commit -m "$msg"
    git push
end

function gc
    set default_msg (git status -s --porcelain)
    read -P "Commit message (leave blank to use status summary): " msg
    test -z "$msg"; and set msg $default_msg
    git add .
    git commit -m "$msg"
end

function gcl
    test (count $argv) -ge 1; or begin
        echo "Usage: gcl user/repo [dest]"
        return 1
    end
    set repo_url "https://github.com/$argv[1]"
    test (count $argv) -gt 1; and git clone $repo_url $argv[2]; or git clone $repo_url
end

function yy
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

function server
    set current_dir (pwd)
    set start_file ""
    test (count $argv) -gt 0; and set start_file $argv[1]
    live-server --mount=/:"$current_dir" "$start_file"
end

function cpmcstudio
    scp -i ~/.ssh/mcpro faustozamparelli@192.168.1.123:$argv[1] $argv[2]
end

function cpmcpro
    scp -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216:$argv[1] $argv[2]
end

function g++
    /opt/homebrew/bin/g++-15 -std=c++23 -I$HOME/.config/cppheaders $argv
end

# ============================
# Misc
# ============================
set -Ux PIP_NO_CACHE_DIR true
set -gx GOKU_EDN_CONFIG_FILE ~/.config/goku/karabiner.edn

if test -d /opt/homebrew/opt/llvm/bin
    contains /opt/homebrew/opt/llvm/bin $PATH; or set -gx PATH /opt/homebrew/opt/llvm/bin $PATH
end

if type -q eza
    alias l "eza -a --git --icons --grid"
    alias ls l
    alias la "eza --long -a"
    alias lt tre
end

# ============================
# tmux auto-attach (LAST)
# ============================
if not set -q TMUX
    # Skip auto-tmux in: VSCode terminal, Emacs vterm, Zed integrated terminal
    if test "$TERM_PROGRAM" != "vscode" -a "$EMACS" != "t" -a "$ZED_TERM" != "true"
        if tmux list-sessions >/dev/null 2>&1
            set recent_session (tmux list-sessions -F "#{session_created} #{session_name}" | sort -n | tail -n1 | awk '{print $2}')
            exec tmux -f ~/.config/tmux/tmux.conf attach-session -t $recent_session
        else
            read -P "No tmux sessions found. Name for new session (default: fish): " name
            test -z "$name"; and set name fish
            exec tmux -f ~/.config/tmux/tmux.conf new-session -s $name
        end
    end
end
