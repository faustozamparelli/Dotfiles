#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh" # Loads all defined colors

IP_ADDRESS=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)
UPDOWN=$(ifstat -i "en0" -b 0.1 1 | tail -n1)
DOWN=$(echo "$UPDOWN" | awk "{ print \$1 }" | cut -f1 -d ".")
DOWN_FORMAT=""
if [ "$DOWN" -gt "999" ]; then
	DOWN_FORMAT=$(echo "$DOWN" | awk '{ printf "%03.0f Mbps", $1 / 1000}')
else
	DOWN_FORMAT=$(echo "$DOWN" | awk '{ printf "%03.0f kbps", $1}')
fi

IS_VPN=$(scutil --nwi | grep -m1 'utun' | awk '{ print $1 }')
if [[ $IS_VPN != "" ]]; then
	COLOR=$RIGHT_BG_COLOR
	ICON=􀎡
	LABEL="VPN"
elif [[ $IP_ADDRESS != "" ]]; then
	COLOR=$RIGHT_BG_COLOR
	ICON=􀙇
	LABEL=$DOWN_FORMAT
else
	COLOR=$RIGHT_BG_COLOR
	ICON=􀙈
	LABEL="Not Connected"
fi

sketchybar --set $NAME background.color=$COLOR \
	icon=$ICON \
	label="$LABEL"
