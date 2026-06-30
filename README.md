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

This writes this Mac's inventory under `~/.config/sync/inventory/<mac-name>/`, stages stable config, and shows `bare status`. Retired VS Code settings and extension names remain tracked for reference, but maintenance and bootstrap never install them.

`bcp` runs `sync-maintain` before committing and pushing, so normal bare pushes refresh inventory and reduce extension conflicts.

Review and commit intentionally:

```sh
bare status
bcp
```

### macOS default applications

The MacBook Air's explicit file-type "Open With" choices are tracked in
`~/.config/duti/defaults.duti`. Browser and mail defaults are excluded because
macOS protects them from this mechanism. This is an occasional manual sync;
`duti` is intentionally not kept installed.

On the Air after changing defaults in macOS, ask an agent to recapture the
explicit Launch Services choices into that file, then commit and push. On the
Pro after pulling, run:

```sh
brew install duti
duti ~/.config/duti/defaults.duti
brew uninstall duti
```

The target applications must already be installed. After applying, `duti` may
also be uninstalled on the Air.

## Terminal Workflow

Ghostty launches Fish, which attaches or creates the tmux session named
`default`. Neovim is the primary editor (`c`, `v`, and `m` all open `nvim`).
Set `FAUSTO_NO_TMUX=1` before starting Fish when an unwrapped shell is needed.

The canonical custom-key inventory is `~/.config/keymaps/registry.tsv`; the
readable reference is `~/.config/keymaps/REFERENCE.md`. Use `Ctrl-Space ?` in
tmux or `Space ?` in Neovim for runtime help. Agents changing a binding must
follow `~/.config/keymaps/AGENTS.md` and run:

```sh
keymap-docs
keymap-docs --check
```

tmux snapshots are explicit: `Ctrl-Space S` saves and `Ctrl-Space R` restores.
They are never written periodically in the background.

## Sync Files

```text
~/.config/sync/agent.md          Agent handoff after dotfiles are already checked out.
~/.config/sync/README.md         Manual sync notes before agent handoff.
~/.config/sync/install-agent.sh  Installs agent dependencies and starts post-checkout setup.
~/.config/sync/maintain.sh       Periodic sync/inventory maintenance.
~/.config/sync/clarifications.md Open questions and findings.
~/.config/sync/inventory/        Per-Mac package/app snapshots.
~/.config/sync/state/            Per-Mac sync bookkeeping.
```
