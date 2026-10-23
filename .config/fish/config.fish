set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx PNPM_HOME $HOME/Library/pnpm

# Keep one deterministic toolchain path on both Macs. fish_add_path normalizes
# paths and prevents the duplicate Homebrew entries produced by editing PATH.
set -g fish_user_paths
fish_add_path -g \
    $HOME/.local/toolchains/bin \
    $HOME/.local/bin \
    $PNPM_HOME/bin \
    $HOMEBREW_PREFIX/bin \
    $HOMEBREW_PREFIX/sbin

# mac-sync maintains a stable Homebrew Python command for editor integrations.
test -f ~/.config/fish/secrets.fish; and source ~/.config/fish/secrets.fish
alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

set -gx THEME dark
set -gx EDITOR nvim
set -gx VISUAL nvim
set fish_greeting ""
set -g pure_enable_git true

#zoxide setup
if type -q zoxide
        zoxide init fish | source
end

# Load Carapace completions in Ghostty, Herdr, and other interactive Fish shells.
if status is-interactive; and type -q carapace
    carapace _carapace fish | source
end

# Use the bundled fzf widgets, with colors inherited from the terminal palette.
if status is-interactive; and type -q fzf
    set -l picker_style (string join ' ' -- \
        '--height=45% --min-height=8 --layout=reverse --border=rounded --padding=0,1' \
        '--info=inline-right --pointer=▸ --marker=•' \
        '--color=bg:-1,bg+:-1,fg:-1,fg+:5,hl:6,hl+:6,border:8,label:5,prompt:5,pointer:5,marker:6,info:8')
    set -gx FZF_COMPLETION_OPTS "$picker_style --border-label=' Complete ' --prompt='complete › ' --no-multi"
    set -gx FZF_CTRL_R_OPTS "$picker_style --border-label=' History ' --prompt='history › ' --no-multi --with-nth=3.. --nth=.."

    # km:fish.history.search
    fzf --fish | FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND= source
    # Older fzf builds still provide history search, but lack fzf_complete.
    if functions -q fzf_complete
        # km:fish.completion.search
        bind tab fzf_complete
        bind -M insert tab fzf_complete
        # km:fish.completion.native
        bind shift-tab complete-and-search
        bind -M insert shift-tab complete-and-search
    end
end

alias nb "jupyter lab"
alias l "eza -a --git"
alias ls l
alias o open
alias py python
alias b bat
alias cl clear
alias sv "source .venv/bin/activate.fish"
alias n "nvim"
alias keymap-docs "$HOME/.config/keymaps/keymap-docs"

# amsc container
alias amsc='docker start amsc >/dev/null && docker exec -it -w /shared-folder amsc /bin/bash --rcfile /u/sw/etc/bash.bashrc -i'

# Route only the stealth profile through the monochrome presentation wrapper.
# Every other Codex invocation keeps the normal full-color TUI.
function codex
    set -l previous ""
    for arg in $argv
        if test "$arg" = "--profile=stealth"; or test "$previous:$arg" = "--profile:stealth"
            "$HOME/.codex/bin/codex-stealth" $argv
            return $status
        end
        set previous "$arg"
    end
    /opt/homebrew/bin/codex $argv
end


#if pressed just enter the message will be 'changes'
function gcp --description "Commit all changes and push (subject + optional description)"
    read -P "Subject (default: 'changes'): " subject
    if test -z "$subject"
        set subject "changes"
    end
    read -P "Description (optional, press enter to skip): " description
    
    git add -A
    if test -z "$description"
        git commit -m "$subject"
    else
        git commit -m "$subject" -m "$description"
    end
    git push
end

# Ghostty starts in the persistent Herdr workspace. Shells created inside Herdr
# inherit HERDR_ENV and therefore do not recurse.
if status is-interactive; and test "$TERM_PROGRAM" = ghostty; and not set -q HERDR_ENV; and not set -q FAUSTO_NO_HERDR
    exec herdr
end

function bcp --description "Bare add -u, commit, and push (subject + optional description)"
    set -lx MAC_SYNC_DEFER_WEB_APP_REPORT 1
    if type -q sync-maintain
        sync-maintain
    else
        ~/.config/sync/maintain.sh
    end

    set -l sync_status $status
    if test $sync_status -ne 0
        echo "sync-maintain failed; bcp stopped." >&2
        return $sync_status
    end

    bare add -u

    read -P "Subject (default: 'changes'): " subject
    if test -z "$subject"
        set subject "changes"
    end
    read -P "Description (optional, press enter to skip): " description

    if test -z "$description"
        bare commit -m "$subject"
    else
        bare commit -m "$subject" -m "$description"
    end
    bare push
    set -l push_status $status
    python3 ~/.config/sync/helium-apps.py report
    set -l report_status $status
    if test $push_status -ne 0
        return $push_status
    end
    return $report_status
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
