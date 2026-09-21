# Dotfiles

This repository is the source of truth for Fausto's Mac configuration. Apps
are shared by default, command-line packages are shared only when listed, and
each Mac may have a tiny local app list or skip list.

## New Mac

These are the only bootstrap steps that cannot live inside the repository.

1. Sign in to the Mac App Store, then install Homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

2. Authenticate and check out the private bare dotfiles repository:

```sh
brew install git gh
gh auth login
gh auth setup-git
mkdir -p "$HOME/.config/git"
git clone --bare https://github.com/faustozamparelli/Dotfiles.git "$HOME/.config/git/dotfiles"
git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" checkout
```

If checkout reports conflicts, move only the listed stock files aside and run
the checkout command again.

3. Install everything and enable automatic sync:

```sh
~/.config/sync/install-agent.sh
```

The installer handles Homebrew casks, Mac App Store IDs, and reviewed pinned
downloads. macOS may still ask once for Accessibility, system extensions,
privileged helpers, or application sign-in; those approvals cannot safely be
automated.

## Installing apps

Use `mac-app` instead of installing an app separately on each Mac:

```sh
mac-app firefox                         # shared Homebrew cask (default)
mac-app share --mas 497799835 Xcode    # shared Mac App Store app
mac-app local transmission             # only this Mac
mac-app temporary handbrake            # install without tracking
mac-app skip spotify                    # exclude a shared app on this Mac
mac-app unskip spotify
```

The command installs the app, commits its manifest entry, and pushes it. Every
other Mac runs `mac-sync` at login and hourly. Direct downloads require a small
reviewed installer under `~/.config/mac-setup/direct`; MagHue is the initial
example and is pinned by SHA-256.

Shared CLI tools live in `~/.config/mac-setup/packages.txt`. Ordinary
`brew install` packages stay local and temporary unless intentionally added to
that short list. Removing an entry never automatically uninstalls software.

Run a sync immediately with:

```sh
mac-sync
```

## Keyboard model

- Right Command is the global Super key, implemented by Karabiner.
- Super controls macOS windows and launches common apps through AeroSpace.
- Command/Alt/Ctrl-Space control Herdr tabs, panes, and workspaces.
- Space controls Neovim commands.

AeroSpace keeps nine predictable workspaces and routes matching windows once
at startup and whenever a new window appears:

```text
A WEB   S TERM   D NOTES   F DOCS   G CHAT   ; MEDIA   N UNI   , ORG   M MISC
```

Use `Super-A/S/D/F/G/;/N/,/M` to switch and add Shift to move a window. `Super-H/J/K/L`
focuses windows, while adding Shift moves them. `Super-M` opens MISC, where
every otherwise-unassigned regular app is routed automatically. Small utility
windows are assigned to MISC or MEDIA; Raycast alone remains a floating overlay
where it was opened. `Super-Tab` focuses the other
display without moving anything. `Super-Shift-Tab` swaps the focused window
with the window on the other display while leaving both workspaces in place.
`Super-Shift-T` moves the entire current workspace to the other display without
swapping windows. `Super-Enter`, `Super-B`, and `Super-O` open or focus Ghostty,
Helium, and Notion on their home workspace. Physical `Fn-H/J/K/L` provides
arrow keys everywhere.

| Workspace | Applications |
| --- | --- |
| WEB | Helium, Safari |
| TERM | Ghostty, Terminal, Console, T3 Code, Visual Studio Code, Codex, UTM |
| NOTES | Notion |
| DOCS | Sioyek, Preview, TextEdit, Books, Dictionary |
| CHAT | Beeper, Discord, ChatGPT, Mail, Messages, FaceTime, Phone, Gmail |
| MEDIA | Spotify, SoundCloud, Music, Podcasts, TV, Photos, QuickTime, Voice Memos, DaVinci Resolve, QuickRecorder, Picture-in-Picture |
| UNI | WeBeep (university materials) |
| ORG | Calendar, Reminders, Apple Notes, Freeform, Journal |
| MISC | Unassigned apps (including MacWhisper, Excel, and Affinity), OrbStack, and system/settings utilities |

Each workspace uses a zero-padding accordion: every tiled app fills the usable
screen and `Super-H/L` moves between apps. `Super-T` toggles the current
workspace between this full-window view and side-by-side tiles. `Super-R`
re-routes every open app to its category, restores regular windows to tiling,
and returns all workspaces to full-window accordion view.

The canonical binding inventory is `~/.config/keymaps/registry.tsv`; the
readable generated table is in `~/.config/sync/README.md`.

## Dotfile maintenance

`bcp` validates the app and keymap configuration, stages the maintained
dotfiles, then asks for a commit message and pushes. `sync-maintain` performs
the validation and staging without committing.
