#!/opt/homebrew/bin/bash

# If the script is being run from nvim, switch to the first free window and run the script from there
if [[ $NVIM_LISTEN_ADDRESS ]]; then
    tmux select-window -t 1
    tmux send-keys '~/.config/tmux/tmux-recursive.sh' C-m
fi

# Recursive fuzzy search for files and directories
if [[ $# -eq 1 ]]; then
    selected=$1
else
    result=$(find ~/Developer/ ~/Downloads/ /Volumes/SD/ ~/.config/fish/ ~/.config/tmux/ ~/.config/nvim/lua/ ~/.config/git/ ~/.config/yabai/ ~/.config/wezterm/ ~/.config/goku/ /usr/local/bin/ ~/.config/sketchybar/ -mindepth 1 -type f | fzf --expect=ctrl-space)
    key=$(head -1 <<< "$result")
    selected=$(tail -1 <<< "$result")
fi

# Exit if no selection was made
if [[ -z $selected ]]; then
    exit 0
fi

# Get the name of the selected directory or file
name=$(basename "$selected")

# Determine if the selection is a file or directory
if [[ -d $selected ]]; then
    if [[ $key == 'ctrl-space' ]]; then
        # If Ctrl-Space was pressed, open a new tmux window with the directory name and cd into the directory
        tmux new-window -n "$name" -c "$selected"
        sleep 0.3
        tmux send-keys 'C-s' C-m
    else
        # If Enter was pressed, cd into the directory in the current window
        tmux send-keys "cd $selected" C-m
        tmux send-keys 'C-s' C-m
    fi
elif [[ -f $selected ]]; then
    # If file, determine the action based on the key pressed
    parent_dir=$(dirname "$selected")
    if [[ $key == 'ctrl-space' ]]; then
        # If Ctrl-Space was pressed, open a new tmux window with the file name, cd into the parent directory, and open the file in nvim
        tmux new-window -n "$name" -c "$parent_dir"
        tmux send-keys "nvim $(basename "$selected")" C-m
    else
        # If Enter was pressed, open the file in the current window
        tmux send-keys "cd $parent_dir && nvim $(basename "$selected")" C-m
    fi
fi
