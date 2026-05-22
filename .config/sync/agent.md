# Agent handoff: new Mac setup

You are configuring Fausto's new Mac after the root README has been followed. The bare dotfiles repo is already checked out, so `~/.config/sync` and the tracked dotfiles are already present. Some apps required by those dotfiles may still be missing.

Use this file as the source of truth. Do not ask about items that are already marked as shared, manual, or local-only.

## Rules

- Prefer Homebrew for apps and packages.
- Use the bare dotfiles repo for config. Do not recreate tracked files manually.
- Do not sync secrets, tokens, browser profiles, histories, caches, app databases, keychains, or machine-local state.
- Do not install local-only or manual-reference apps unless Fausto explicitly asks.
- Leave commits manual.

Bare repo helper. Use Fausto's existing `bare` alias.

```sh
bare pull --ff-only
bare status
```

## 1. Install Shared Tools

Install on every Mac:

```sh
brew install bat bun eza fish fisher fzf gh git git-delta micro mole pnpm uv wget zoxide
brew install --cask antinote cleanmymac codex codexbar font-sf-mono ghostty helium-browser karabiner-elements maccy microsoft-outlook rectangle-pro shottr spotify t3-code visual-studio-code wispr-flow
```

Setup-only `duti`:

```sh
brew install duti
duti -s com.microsoft.VSCode public.python-script all
duti -s com.microsoft.VSCode public.shell-script all
duti -s com.microsoft.VSCode public.json all
duti -s com.microsoft.VSCode public.plain-text all
duti -s com.microsoft.VSCode public.source-code all
duti -s com.microsoft.VSCode public.c-source all
duti -s com.microsoft.VSCode public.c-plus-plus-source all
duti -s com.microsoft.VSCode public.c-header all
duti -s com.microsoft.VSCode public.objective-c-source all
duti -s com.microsoft.VSCode public.swift-source all
duti -s com.microsoft.VSCode public.javascript-source all
duti -s com.microsoft.VSCode public.typescript-source all
duti -s com.microsoft.VSCode net.daringfireball.markdown all
brew uninstall duti
```

## 2. Apply macOS Defaults

These values were confirmed on Fausto's current Mac on 2026-05-20, except `ShowPathbar`, which is desired baseline behavior.

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

## 3. Restore Config From Dotfiles

The bare repo checkout is enough. Verify these are present after `bare pull`:

```text
~/.config/karabiner/karabiner.json
~/.config/fish/config.fish
~/.config/fish/fish_plugins
~/.config/git/.gitconfig
~/.config/git/.gitignore
~/.config/ghostty/config
~/.config/micro
~/.zshrc
~/.gitconfig
~/Library/Application Support/Code/User/settings.json
~/Library/Application Support/Code/User/keybindings.json
~/.config/sync
```

Fish is the primary shell. `~/.zshrc` is only fallback shell config.

Do not restore old removed configs: `aerospace`, `iterm-config`, `sketchybar`, `skhd`, `tmux`, `wezterm`, `yabai`, `zed`, or `opencode`.

Never sync `~/.config/fish/fish_variables`; it contains secrets and machine-specific PATH state.

## 4. Restore VS Code

Install shared extensions:

```sh
while IFS= read -r extension; do
  [ -n "$extension" ] && code --install-extension "$extension"
done < ~/.config/sync/vscode-extensions.txt
```

Settings and keybindings come from the bare repo.

Extension sync is maintained by `~/.config/sync/maintain.sh`. The shared desired list is `~/.config/sync/vscode-extensions.txt`; each Mac keeps a small last-seen marker under `~/.config/sync/state/<mac-name>/` so local extension changes and remote extension changes can be distinguished.

## 5. Manual Reminders

Remind Fausto to install or configure manually:

```text
Amphetamine app: no reliable Homebrew cask found; remind Fausto to install manually/App Store on other Macs.
Perplexity app: no reliable Homebrew cask found; remind Fausto to install manually on other Macs.
Solves app: installed through the App Store; remind Fausto to install manually on other Macs.
CleanMyMac config
Microsoft Outlook sign-in
Spotify sign-in
Karabiner permissions
Rectangle Pro license/settings
Shottr license/settings
Codex/current agent sign-in and extension/MCP/skill sync check
```

## 6. Local-Only Reference

These were present or relevant on the source Mac but are not shared installs:

```text
Affinity
Audacity
DaVinci Resolve
Legcord
MATLAB
Microsoft Excel
MySielteID
OBS
QuickRecorder
Safe Exam Browser
Send to Kindle
Telegram
UTM
Xcode
uBlock Origin Lite
cmake
go
graphviz
hugo
jupyterlab
openjdk
rust
typst
```

## 7. Investigate Later

Report findings, but do not sync without approval:

```text
Rectangle Pro: enable/check its built-in iCloud configuration sync. Do not track local license files.
Rectangle Pro: Fausto has exported the config; remind him to import/update it manually on other Macs.
Shottr: Fausto has exported the settings; remind him to import/update them manually on other Macs.
Codex/current agent: syncs by default; no tracked config needed.
```

## 8. Finish

Run:

```sh
~/.config/sync/maintain.sh
bare status
```

Tell Fausto what was installed, what needs manual login, and any unresolved sync findings.
