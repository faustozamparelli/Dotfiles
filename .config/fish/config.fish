# ----------------------------
# Core: Homebrew + PATH setup
# ----------------------------
set -gx HOME_BREW /opt/homebrew

# Basic envs that we need early
set -gx JAVA_HOME $HOME_BREW/opt/openjdk
set -x PNPM_HOME "$HOME/Library/pnpm"

# Put Homebrew first, then sbin, then virtualenvs
set -gx PATH $HOME_BREW/bin $HOME_BREW/sbin $HOME/.virtualenvs/ml/bin $PATH
source (brew --prefix asdf)/libexec/asdf.fish

# Add java/openvpn after Homebrew so they don't override
set -gx PATH $JAVA_HOME/bin /opt/homebrew/opt/openvpn/sbin $PATH

# MANPATH: prefer Homebrew manpages
set -gx MANPATH $HOME_BREW/share/man $MANPATH
set -gx MANPATH ~/man-pages $MANPATH #git clone http://git.kernel.org/pub/scm/docs/man-pages/man-pages

# If asdf shims exist, prepend them to PATH (so shims override system, but after Homebrew)
if test -z "$ASDF_DATA_DIR"
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

if test -d $_asdf_shims
    if not contains $_asdf_shims $PATH
        set -gx PATH $_asdf_shims $PATH
    end
end
set --erase _asdf_shims

# Ensure PNPM_HOME is in PATH
if not contains $PNPM_HOME $PATH
    set -gx PATH $PNPM_HOME $PATH
end

# If you use TinyTeX for LaTeX workshop:
set -gx PATH $PATH $HOME/Library/TinyTeX/bin/universal-darwin

# C/C++ include paths
set -gx C_INCLUDE_PATH $HOME_BREW/include
set -gx CPLUS_INCLUDE_PATH $HOME_BREW/include

# ----------------------------
# Shell basics & niceties
# ----------------------------
set fish_greeting ""

# Editor
set -gx EDITOR nvim
alias nh 'NVIM_APPNAME=nvimheavy nvim'
alias nn nvim_configuration_swticher.sh

# thefuck
if type -q thefuck
	thefuck --alias | source
end

# zoxide
if type -q zoxide
	zoxide init fish | source
end

# fifc defaults
set -Ux fifc_editor nvim
set -U fifc_fd_opts --hidden

#Themes
if test (osascript -e 'tell app "System Events" to tell appearance preferences to get dark mode') = "true"
	set -gx THEME "dark"
	set -gx BAT_THEME "Dracula"
else
	set -gx THEME "light"
	set -gx THEME "light"
end


#fzf search and cd into dir
function f
    if test (count $argv) -eq 0
        cd (fd --type directory --no-ignore | fzf)
    else
        cd $argv
    end
end

# ----------------------------
# Useful aliases
# ----------------------------

# alias dev 'open http://localhost:3000; pnpm run dev'
# alias npm="echo '❌ Use pnpm instead.'"
# alias npx="pnpm dlx"

alias lg lazygit
alias glog "git lg"
alias glg "tig"

alias tk "tmux kill-server"
alias jp "jupyter notebook"
alias o "open"
alias py "python"
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
alias cursor "cursor -r"
alias study "py $HOME/Documents/Developer/StudyTracker/study.py"

# Git bare helper
alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

# ----------------------------
# Functions (single definitions)
# ----------------------------

function cd
	builtin cd $argv
	if set -q TMUX
		if tmux has-session >/dev/null 2>&1
			tmux rename-window (basename $PWD)
		end
	end
end

function z_tmux
	__zoxide_z $argv
	if test $status -eq 0
		if set -q TMUX
			if tmux has-session >/dev/null 2>&1
				tmux rename-window (basename $PWD)
			end
		end
	end
end

function zn
	__zoxide_z $argv
	if test $status -eq 0
		if set -q TMUX
			if tmux has-session >/dev/null 2>&1
				tmux rename-window (basename $PWD)
			end
		end
		n .
	else
		echo "Directory not found!"
	end
end

function n
	if test (count $argv) -gt 0 -a "$argv[1]" != "."
		if set -q TMUX
			tmux rename-window (basename -- $argv[1])
		end
		nvim $argv
	else
		nvim .
	end
end

# curl + jq helper: split args with -- (curl args first, then --, then jq args)
# function curljq
#     set curl_args
#     set jq_args
#     set split false
#     for arg in $argv
#         if test "$arg" = "--"
#             set split true
#             continue
#         end
#         if test "$split" = true
#             set jq_args $jq_args $arg
#         else
#             set curl_args $curl_args $arg
#         end
#     end
#     /usr/bin/curl -s $curl_args | jq $jq_args
# end

function gsp
	git status -s --porcelain
end

function gcp
	git pull --ff-only
	set default_msg (git status -s --porcelain)
	read -P "Commit message (leave blank to use status summary): " msg
	if test -z "$msg"
		set msg $default_msg
	end
	git add .
	git commit -m "$msg"
	git push
end

function gc
	set default_msg (git status -s --porcelain)
	read -P "Commit message (leave blank to use status summary): " msg
	if test -z "$msg"
		set msg $default_msg
	end
	git add .
	git commit -m "$msg"
end

function gcl
	if test (count $argv) -ge 1
		set repo_url "https://github.com/$argv[1]"
		if test (count $argv) -gt 1
			git clone $repo_url $argv[2]
		else
			git clone $repo_url
		end
	else
		echo "Usage: gcl user/repo [dest]"
	end
end

function yy
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (cat -- "$tmp"); and test -n "$cwd" ; and test "$cwd" != "$PWD"
		cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function server
	set current_dir (pwd)
	if test (count $argv) -gt 0
		set start_file $argv[1]
	else
		set start_file ""
	end
	live-server --mount=/:"$current_dir" "$start_file"
end

function cpmcstudio
	scp -i ~/.ssh/mcpro faustozamparelli@192.168.1.123:$argv[1] $argv[2]
end

function cpmcpro
	scp -i ~/.ssh/mcstudio faustozamparelli@192.168.1.216:$argv[1] $argv[2]
end

# g++ wrapper using Homebrew 15
function g++
    /opt/homebrew/bin/g++-15 -std=c++23 -I$HOME/.config/cppheaders $argv
end
alias gcc="/opt/homebrew/bin/gcc-15"
alias cpp="/opt/homebrew/bin/cpp-15"

# ----------------------------
# Misc env / tool settings
# ----------------------------
set -Ux PIP_NO_CACHE_DIR true
set -gx GOKU_EDN_CONFIG_FILE ~/.config/goku/karabiner.edn

# API keys (you provided earlier)
set -Ux GROQ_API_KEY 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

# Add LLVM bin (if needed) but ensure it doesn't override core Homebrew bin
if test -d /opt/homebrew/opt/llvm/bin
    if not contains /opt/homebrew/opt/llvm/bin $PATH
        set -gx PATH /opt/homebrew/opt/llvm/bin $PATH
    end
end

# eza aliases (if installed)
if type -q eza
    alias l "eza --color=always --long -a --git --no-filesize --icons=always --no-time --no-user --no-permissions --grid"
    alias ls "l"
    alias la "eza --long --total-size -a --no-time --no-user --no-permissions"
    alias lt "tre"
end

# ----------------------------
# Auto-attach tmux at login (preserve your logic)
# ----------------------------
if not set -q TMUX
    if test "$TERM_PROGRAM" != "vscode" -a "$EMACS" != "t"
        if tmux list-sessions >/dev/null 2>&1
            set recent_session (tmux list-sessions -F "#{session_created} #{session_name}" | sort -n | tail -n1 | awk '{print $2}')
            if test -n "$recent_session"
                exec tmux -f ~/.config/tmux/tmux.conf attach-session -t $recent_session
            else
                exec tmux -f ~/.config/tmux/tmux.conf attach
            end
        else
            read -P "No tmux sessions found. Name for new session (leave blank for 'fish'): " name
            if test -z "$name"
                set name fish
            end
            exec tmux -f ~/.config/tmux/tmux.conf new-session -s $name
        end
    end
end
