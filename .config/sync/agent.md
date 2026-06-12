# Agent Handoff: Mac Sync

Use this file when finishing a new Mac setup or doing periodic cleanup. Run
`sync-maintain`, edit the current Mac's review file only after asking Fausto,
then run `sync-maintain` again.

## Rules

- Prefer Homebrew for packages and casks.
- Use the bare dotfiles repo; do not recreate tracked config manually.
- Do not sync secrets, tokens, browser profiles, histories, caches, app databases,
  keychains, or machine-local state.
- Newly installed Brew packages, casks, and App Store apps default to local.
- Ask Fausto before moving `[.]` from `local` to `shared`.
- Never add a remove bucket or uninstall software from the sync script.
- Leave commit/push manual unless Fausto asks you to use `bcp`.

## Source Of Truth

`software-<mac-name>.txt` is the editable source of truth for Brew packages,
casks, and App Store apps. Move `[.]` between the `shared` and `local`
brackets; do not edit the generated Brew/cask/App Store files under `shared/`.

`inventory/<mac-name>/` is observed state only. VS Code extensions, App
Shortcuts, and Marta's portable configuration files remain automatically shared.

## Periodic Cleanup

1. Run:

   ```sh
   sync-maintain
   ```

2. Ask Fausto which local items should be shared.
3. Move the approved items' `[.]` markers to `shared` in
   `software-<mac-name>.txt`.
4. Run:

   ```sh
   sync-maintain
   bare status
   ```

5. Summarize what was installed, what was promoted to shared, and what remains
   local.
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
