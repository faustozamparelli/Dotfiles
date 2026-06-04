# Agent Handoff: Mac Sync

Use this file when finishing a new Mac setup or doing periodic cleanup. Keep the
workflow simple: run `sync-maintain`, edit shared lists only after asking Fausto,
then run `sync-maintain` again.

## Rules

- Prefer Homebrew for packages and casks.
- Use the bare dotfiles repo; do not recreate tracked config manually.
- Do not sync secrets, tokens, browser profiles, histories, caches, app databases,
  keychains, or machine-local state.
- If an installed item is not in `shared/`, ask Fausto before promoting it.
- Leave commit/push manual unless Fausto asks you to use `bcp`.

## Source Of Truth

```text
~/.config/sync/shared/brew-leaves.txt
~/.config/sync/shared/brew-casks.txt
~/.config/sync/shared/mas-apps.txt
~/.config/sync/shared/vscode-extensions.txt
~/.config/sync/shared/macos-keyboard-shortcuts/
```

`inventory/<mac-name>/` is observed state only. Use it to compare Macs and decide
what to ask Fausto.

## Periodic Cleanup

1. Run:

   ```sh
   sync-maintain
   ```

2. Copy the checklist candidates from the output and ask Fausto which should be
   shared.
3. Add approved items to the matching file in `shared/`.
4. Run:

   ```sh
   sync-maintain
   bare status
   ```

5. Summarize what was installed, what was promoted to shared, and what remains
   machine-specific by inference.
6. Ask Fausto whether to commit/push with `bcp`.

## New Mac Setup

1. Verify the bare repo is present:

   ```sh
   bare pull --ff-only
   bare status
   ```

2. Install minimal agent dependencies if needed:

   ```sh
   ~/.config/sync/install-agent.sh
   ```

3. Run:

   ```sh
   sync-maintain
   ```

4. The script installs missing shared Brew packages, casks, App Store apps, VS
   Code extensions, and shared App Shortcuts.
5. Remind Fausto to handle manual sign-ins/licenses: Outlook, Spotify,
   CleanMyMac, Rectangle Pro, Shottr, Karabiner permissions, Codex/agent apps.
6. Run `bare status` and report the result.

## macOS Defaults

Apply these once on a new Mac if they are not already set:

```sh
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.1
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
```
