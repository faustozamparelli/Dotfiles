# Dotfiles

This repo is the source of truth for Fausto's Mac dotfiles and sync automation.

## New Mac: Get To Start State

Read this on GitHub in the browser, then run these commands manually.

1. Install Homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
```

2. Install GitHub CLI and authenticate. This repo is private, so do this before cloning dotfiles:

```sh
brew install git gh
gh auth login
gh auth setup-git
```

3. Clone and check out the bare dotfiles repo:

```sh
mkdir -p "$HOME/.config/git"
git clone --bare https://github.com/faustozamparelli/Dotfiles.git "$HOME/.config/git/dotfiles"
git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" checkout
```

If checkout reports conflicts, move the listed stock files aside and rerun the checkout command.

At this point the dotfiles are present, including the `bare` alias and `~/.config/sync`.

4. Start the post-checkout automation:

```sh
~/.config/sync/install-agent.sh
```

5. Sign in to Codex or another agent, then give it:

```text
~/.config/sync/agent.md
```

## Maintenance

After setup, use Fish and run:

```sh
sync-maintain
```

This syncs VS Code extensions, writes this Mac's inventory under `~/.config/sync/inventory/<mac-name>/`, stages stable config, and shows `bare status`.

VS Code extension sync uses `~/.config/sync/vscode-extensions.txt` as the shared desired list. If this Mac changed extensions since its last maintenance, maintenance adopts this Mac's list and the last pushed Mac wins. If this Mac did not change extensions but the shared list changed, maintenance installs/uninstalls locally to match it.

`bcp` runs `sync-maintain` before committing and pushing, so normal bare pushes refresh inventory and reduce extension conflicts.

Review and commit intentionally:

```sh
bare status
bcp
```

## Sync Files

```text
~/.config/sync/agent.md          Agent handoff after dotfiles are already checked out.
~/.config/sync/install-agent.sh  Installs agent dependencies and starts post-checkout setup.
~/.config/sync/maintain.sh       Periodic sync/inventory maintenance.
~/.config/sync/clarifications.md Open questions and findings.
~/.config/sync/inventory/        Per-Mac package/app snapshots.
~/.config/sync/state/            Per-Mac sync bookkeeping.
```
