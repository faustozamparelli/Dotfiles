#!/usr/bin/env bash

# Fuzzy search for files and directories
if [[ $# -eq 1 ]]; then
    selected=$1
else
    # First, search for files and directories at depth 1 in ~/ and ~/.config/
    selected=$(find ~/ ~/.config/ ~/Downloads/ ~/Developer/ -mindepth 1 -maxdepth 1 -type d -o -type f | fzf)
    # If no selection was made, search recursively in the other directories
    if [[ -z $selected ]]; then
        selected=$(find ~/Developer/ ~/Downloads/ /Volumes/SD/ ~/.config/fish/ ~/.config/tmux/ ~/.config/nvim/ -mindepth 1 -type d -o -type f | fzf)
    fi
fi

# Exit if no selection was made
if [[ -z $selected ]]; then
    exit 0
fi

# Get the name of the selected directory or file
name=$(basename "$selected")

# Check if a window with the same name already exists
if tmux list-windows -F "#{window_name}" | grep -q "^$name$"; then
    # If a window with the same name exists, switch to that window
    tmux select-window -t "$name"
    exit 0
fi

# Determine if the selection is a file or directory
if [[ -d $selected ]]; then
    # If directory, open a new tmux window with the directory name and cd into the directory
    tmux new-window -n "$name" -c "$selected"
    sleep 0.3
    tmux send-keys 'C-z' C-m
elif [[ -f $selected ]]; then
    # If file, open a new tmux window with the file name, cd into the parent directory, and open the file in nvim
    parent_dir=$(dirname "$selected")
    tmux new-window -n "$name" -c "$parent_dir"
    tmux send-keys "nvim $(basename "$selected")" C-m
fi

# If the script is being run from nvim, switch to the first free window and run the script from there
if [[ $NVIM_LISTEN_ADDRESS ]]; then
    tmux select-window -t 1
    tmux send-keys './tmux-sessionzer.sh' C-m
fi
