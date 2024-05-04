#!/bin/bash

# Get the total CPU usage from the top command
CPU_USAGE=$(top -l 1 | awk '/CPU usage:/ {print $3}') # get the user cpu usage
CPU_USAGE=${CPU_USAGE%\%*} # remove the % sign at the end

# Convert CPU usage to an integer
CPU_PERCENT=$(printf "%.0f" $CPU_USAGE)

# Update the SketchyBar label
sketchybar --set $NAME label="$CPU_PERCENT%"
