#!/bin/bash
# One normal desktop with immediate window operations; reapplied by mac-sync.
set -euo pipefail
write() {
  local domain="$1" key="$2" kind="$3" value="$4" current
  current="$(/usr/bin/defaults read "$domain" "$key" 2>/dev/null || true)"
  if [[ "$current" != "$value" ]]; then
    if [[ "$kind" == bool ]]; then
      [[ "$value" == 1 ]] && value=true || value=false
    fi
    /usr/bin/defaults write "$domain" "$key" "-$kind" "$value"
  fi
}
write NSGlobalDomain NSAutomaticWindowAnimationsEnabled bool 0
write NSGlobalDomain NSWindowResizeTime float 0.001
write NSGlobalDomain NSAutomaticWindowTabbingEnabled bool 0
write NSGlobalDomain AppleWindowTabbingMode string manual
write NSGlobalDomain AppleActionOnDoubleClick string Fill
write com.apple.dock autohide-delay float 0
write com.apple.dock autohide-time-modifier float 0
write com.apple.dock expose-animation-duration float 0
write com.apple.dock launchanim bool 0
write com.apple.dock mineffect string scale
write com.apple.dock mru-spaces bool 0
write com.apple.dock workspaces-auto-swoosh bool 0
write com.apple.WindowManager GloballyEnabled bool 0
write com.apple.WindowManager EnableTiledWindowMargins bool 0
write org.hammerspoon.Hammerspoon MJShowDockIconKey bool 0
write org.hammerspoon.Hammerspoon MJShowConsoleWindowOnLaunch bool 0
write org.hammerspoon.Hammerspoon SUEnableAutomaticChecks bool 1

# A LaunchAgent also works on Studio, where there is no console login at setup.
agent="$HOME/Library/LaunchAgents/com.fausto.window-workflow.plist"
mkdir -p "$HOME/Library/LaunchAgents"
temporary="$(mktemp)"
trap 'rm -f "$temporary"' EXIT
cat > "$temporary" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.fausto.window-workflow</string>
<key>ProgramArguments</key><array><string>/usr/bin/open</string><string>-g</string><string>/Applications/Hammerspoon.app</string></array>
<key>RunAtLoad</key><true/>
<key>LimitLoadToSessionType</key><string>Aqua</string>
</dict></plist>
PLIST
if ! cmp -s "$temporary" "$agent"; then
  cp "$temporary" "$agent"
  chmod 600 "$agent"
fi
if launchctl print "gui/$(id -u)" >/dev/null 2>&1 &&
   ! launchctl print "gui/$(id -u)/com.fausto.window-workflow" >/dev/null 2>&1; then
  launchctl bootstrap "gui/$(id -u)" "$agent"
fi
