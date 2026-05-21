# Manual Sync Notes

This folder is the manual handoff layer before an agent continues the rest of
new Mac setup from `agent.md`.

## macOS Keyboard Shortcuts

Track only keyboard shortcuts manually added in System Settings under Keyboard
Shortcuts > App Shortcuts. These live in `NSUserKeyEquivalents` dictionaries.
All Applications shortcuts live in `NSGlobalDomain`; app-specific shortcuts live
in each app's own preference domain.

Do not track the whole `~/.GlobalPreferences.plist` or app preference plists for
this. Track only the extracted `NSUserKeyEquivalents` dictionaries under
`~/.config/sync/macos-keyboard-shortcuts/`.

Find every domain on the current Mac that has manually added App Shortcuts:

```sh
find "$HOME/Library/Preferences" -maxdepth 1 -name '*.plist' -print0 |
  xargs -0 -n 1 sh -c 'for f do
    if /usr/libexec/PlistBuddy -c "Print :NSUserKeyEquivalents" "$f" >/dev/null 2>&1; then
      basename "$f" .plist
    fi
  done' sh
```

Export from the configured Mac:

```sh
mkdir -p ~/.config/sync/macos-keyboard-shortcuts
for domain in NSGlobalDomain com.apple.Safari net.imput.helium; do
  defaults read "$domain" NSUserKeyEquivalents > ~/.config/sync/macos-keyboard-shortcuts/"$domain".plist
done
bare add ~/.config/sync/macos-keyboard-shortcuts
bare commit -m "Track macOS app keyboard shortcuts"
bare push
```

Restore on a new Mac after pulling dotfiles:

```sh
for file in ~/.config/sync/macos-keyboard-shortcuts/*.plist; do
  domain="$(basename "$file" .plist)"
  defaults write "$domain" NSUserKeyEquivalents "$(cat "$file")"
done
killall cfprefsd
```

Then log out and log back in so System Settings and apps reload the preference
cache.

`com.apple.symbolichotkeys.plist` contains many built-in system shortcut
toggles and remaps. Track it only if the goal is to mirror changed built-in
macOS shortcut categories, not just manually added App Shortcuts.
