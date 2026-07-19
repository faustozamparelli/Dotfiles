#!/bin/sh

# Reliable yabai navigation for skhd. macOS Space transitions are asynchronous,
# so Space focus and window focus must not be issued back-to-back blindly.

set -u

YABAI=/opt/homebrew/bin/yabai
JQ=/usr/bin/jq

focus_space() {
    selector=$1
    before=$($YABAI -m query --spaces --space 2>/dev/null | $JQ -r '.index') || return 0

    if [ "$selector" != "$before" ]; then
        $YABAI -m space --focus "$selector" 2>/dev/null || return 0

        # Give Mission Control time to begin the transition, then poll until the
        # destination is active and accepts focus. This avoids the click-to-focus bug.
        /bin/sleep 0.12
    fi
    attempt=0
    while [ "$attempt" -lt 20 ]; do
        space=$($YABAI -m query --spaces --space 2>/dev/null) || {
            /bin/sleep 0.05
            attempt=$((attempt + 1))
            continue
        }
        active=$(printf '%s' "$space" | $JQ -r '.index')

        case "$selector" in
            prev|next)
                [ "$active" != "$before" ] || {
                    /bin/sleep 0.05
                    attempt=$((attempt + 1))
                    continue
                }
                ;;
            *)
                [ "$active" = "$selector" ] || {
                    /bin/sleep 0.05
                    attempt=$((attempt + 1))
                    continue
                }
                ;;
        esac

        # Preserve the window macOS/yabai restored on its own.
        focused=$($YABAI -m query --windows 2>/dev/null | $JQ -r \
            --argjson space "$active" \
            '[.[] | select(.space == $space and ."has-focus" == true)] | .[0].id // 0')
        [ "$focused" -eq 0 ] || return 0

        # Empty Spaces legitimately have nothing to focus.
        candidate=$(printf '%s' "$space" | $JQ -r '."first-window" // 0')
        [ "$candidate" -ne 0 ] || return 0

        $YABAI -m window "$candidate" --focus 2>/dev/null && return 0
        /bin/sleep 0.05
        attempt=$((attempt + 1))
    done

    return 0
}

focus_window() {
    direction=$1
    layout=$($YABAI -m query --spaces --space 2>/dev/null | $JQ -r '.type') || return 0

    if [ "$layout" = stack ]; then
        $YABAI -m window --focus "stack.$direction" 2>/dev/null && return 0
        if [ "$direction" = next ]; then
            $YABAI -m window --focus stack.first 2>/dev/null
        else
            $YABAI -m window --focus stack.last 2>/dev/null
        fi
    else
        $YABAI -m window --focus "$direction" 2>/dev/null && return 0
        if [ "$direction" = next ]; then
            $YABAI -m window --focus first 2>/dev/null
        else
            $YABAI -m window --focus last 2>/dev/null
        fi
    fi
}

focus_horizontal_or_space() {
    direction=$1
    space_direction=$2
    layout=$($YABAI -m query --spaces --space 2>/dev/null | $JQ -r '.type') || return 0

    # In BSP, H/L traverses the split before crossing its outer edge. In a
    # fullscreen stack, J/K owns app navigation, so H/L changes Spaces directly.
    if [ "$layout" = bsp ]; then
        $YABAI -m window --focus "$direction" 2>/dev/null && return 0
    fi
    focus_space "$space_direction"
}

swap_window() {
    direction=$1
    layout=$($YABAI -m query --spaces --space 2>/dev/null | $JQ -r '.type') || return 0

    if [ "$layout" = stack ]; then
        $YABAI -m window --swap "stack.$direction" 2>/dev/null && return 0
        if [ "$direction" = next ]; then
            $YABAI -m window --swap stack.prev 2>/dev/null
        else
            $YABAI -m window --swap stack.next 2>/dev/null
        fi
    else
        $YABAI -m window --swap "$direction" 2>/dev/null && return 0
        if [ "$direction" = next ]; then
            $YABAI -m window --swap first 2>/dev/null
        else
            $YABAI -m window --swap last 2>/dev/null
        fi
    fi
}

move_window() {
    destination=$1
    $YABAI -m window --space "$destination" --focus 2>/dev/null || return 0
    $YABAI -m space --balance 2>/dev/null || true
}

case ${1:-} in
    focus-window) focus_window "${2:?missing direction}" ;;
    horizontal) focus_horizontal_or_space "${2:?missing window direction}" "${3:?missing space direction}" ;;
    space) focus_space "${2:?missing destination}" ;;
    swap) swap_window "${2:?missing direction}" ;;
    move) move_window "${2:?missing destination}" ;;
    *) exit 2 ;;
esac
