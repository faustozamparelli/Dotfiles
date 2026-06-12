# Mac Sync Workflow

This folder keeps Fausto's MacBook Air and MacBook Pro aligned through the bare
dotfiles repo. Run one command:

```sh
sync-maintain
```

`bcp` already runs `sync-maintain` before committing and pushing bare dotfiles.

## What The Script Does

- Pulls the bare dotfiles repo with `--ff-only`.
- Refreshes this Mac's inventory under `inventory/<mac-name>/`.
- Reconciles the editable software buckets in `review/<mac-name>.txt`.
- Installs missing shared Homebrew packages, casks, and App Store apps.
- Syncs VS Code extensions both ways, including removals.
- Exports/applies manually added macOS App Shortcuts from `shared/macos-keyboard-shortcuts/`.
- Tracks Marta's portable `conf.marco` and `favorites.marco` settings.
- Stages tracked sync/dotfile paths. Commits and pushes stay manual.

## Files

```text
shared/                  desired state for both Macs
inventory/<mac-name>/    what is installed on each Mac right now
review/<mac-name>.txt    editable shared/local software choices
state/<mac-name>/        last-seen markers used by sync logic
```

The files under `shared/` are generated. Edit `review/<mac-name>.txt` instead.
Move `[.]` between the `shared` and `local` brackets, then run
`sync-maintain`:

```text
# type  item       shared  local
cask    marta      []      [.]
```

Newly installed Brew packages, casks, and App Store apps default to local. A
shared item is required and auto-installed on both Macs. To stop tracking an
item, uninstall it normally and run `sync-maintain`; never delete or add a
remove bucket. Externally uninstalling a shared item declassifies surviving
copies to local and stops automatic installation.

VS Code extensions, App Shortcuts, and Marta's portable settings remain
automatically shared.

`bcp` runs `sync-maintain` first. When new software is discovered, `bcp` opens
the review file in VS Code through the Fish `c` function and stops before
committing. Move the bracket dots, save, and run `bcp` again.

## Periodic Cleanup

1. Run `sync-maintain`, or just run `bcp` when committing dotfiles.
2. Edit `review/<mac-name>.txt` and move bracket dots for software that should be shared.
3. Run `sync-maintain` again to apply the choices.
4. Commit/push with `bcp` when the result looks right.

## New Mac Setup

Ask an agent:

```text
Use ~/.config/sync/agent.md to finish this new Mac setup.
```

Manual start:

1. Follow the root dotfiles README until the bare repo exists.
2. Run `~/.config/sync/install-agent.sh`.
3. Sign in to an agent app.
4. Give the agent `~/.config/sync/agent.md`.

## Keyboard Shortcuts

Only manually added App Shortcuts are shared. The script uses
`NSUserKeyEquivalents` for known domains and does not track the full macOS
keyboard shortcut plist. After shortcut changes apply, reopening apps or logging
out may be needed for macOS to reload preferences.
