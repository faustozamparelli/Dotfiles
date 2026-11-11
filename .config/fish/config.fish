set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx PNPM_HOME $HOME/Library/pnpm

# Keep one deterministic toolchain path on all Macs. fish_add_path normalizes
# paths and prevents the duplicate Homebrew entries produced by editing PATH.
set -g fish_user_paths
fish_add_path -g \
    $HOME/.local/toolchains/bin \
    $HOME/.local/bin \
    $PNPM_HOME/bin \
    $HOMEBREW_PREFIX/bin \
    $HOMEBREW_PREFIX/sbin

test -f ~/.config/fish/secrets.fish; and source ~/.config/fish/secrets.fish
alias bare "/opt/homebrew/bin/git --git-dir=$HOME/.config/git/dotfiles --work-tree=$HOME"

set -gx THEME dark
set -gx EDITOR /usr/bin/nano
set -gx VISUAL /usr/bin/nano
set fish_greeting ""

# Interactive navigation and completions.
if status is-interactive; and type -q zoxide
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

alias l "eza -a --git"
alias ls l
alias py python
alias cl clear
alias sv "source .venv/bin/activate.fish"
alias keymap-docs "$HOME/.config/keymaps/keymap-docs"

# amsc container
alias amsc='docker start amsc >/dev/null && docker exec -it -w /shared-folder amsc /bin/bash --rcfile /u/sw/etc/bash.bashrc -i'

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

    bare add -u; or return $status

    # A clean tree may still contain commits from a previous failed push.
    bare diff --cached --quiet
    set -l diff_status $status
    if test $diff_status -gt 1
        return $diff_status
    end

    if test $diff_status -eq 1
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
        set -l commit_status $status
        if test $commit_status -ne 0
            echo "Commit failed; bcp stopped before push." >&2
            return $commit_status
        end
    end
    bare push
    set -l push_status $status
    python3 ~/.config/sync/manual-actions.py
    set -l report_status $status
    if test $push_status -ne 0
        return $push_status
    end
    return $report_status
end

# Added by OrbStack: command-line tools and integration
if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end
