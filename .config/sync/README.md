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
- Installs missing shared Homebrew packages, casks, and App Store apps.
- Syncs VS Code extensions both ways, including removals.
- Exports/applies manually added macOS App Shortcuts from `shared/macos-keyboard-shortcuts/`.
- Prints installed items and checklist candidates that are installed here but not shared.
- Stages tracked sync/dotfile paths. Commits and pushes stay manual.

## Files

```text
shared/                  desired state for both Macs
inventory/<mac-name>/    what is installed on each Mac right now
state/<mac-name>/        last-seen markers used by sync logic
```

If something is in `shared/`, both Macs should have it. If it only appears in an
`inventory/<mac-name>/` file, treat it as machine-specific unless Fausto says to
promote it to shared.

## Periodic Cleanup

Ask an agent:

```text
Run my Mac sync periodic cleanup. Run sync-maintain, show me the checklist
candidates, ask what should be promoted to shared, update the shared lists, run
sync-maintain again, then show the final report and bare status.
```

Human steps:

1. Run `sync-maintain`, or just run `bcp` when committing dotfiles.
2. Review checklist candidates printed by the script.
3. Add approved shared items to `shared/brew-leaves.txt`, `shared/brew-casks.txt`, or `shared/mas-apps.txt`.
4. Run `sync-maintain` again so missing shared items install and inventory refreshes.
5. Commit/push with `bcp` when the result looks right.

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
