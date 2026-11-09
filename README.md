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
mac-app skip firefox                    # exclude a shared app on this Mac
mac-app unskip firefox
mac-app remove firefox                  # remove here; run mac-sync on the other Mac
```

The command records the app change, commits it, and pushes it. `mac-app remove`
also removes the shared app locally and records its retirement; run `mac-sync`
on the other Mac to apply the removal there. At login and hourly a LaunchAgent
exchanges menu-shortcut data and checks manifests; it does not install apps or
pull executable configuration. Direct downloads require a small reviewed installer under
`~/.config/mac-setup/direct` with a pinned checksum.

Managed installs on the MacBook Air always join the common shared set. Use
`local` for extra Pro/Studio apps; `share` promotes an app into the common set
and removes duplicate local rows. The Studio and Pro can keep different extras.
The sync manual lists portable settings support for all shared apps. Select
reviewed preference profiles with `app-preferences.py enable/disable`, then
publish with `bcp`; new profiles are opt-in.

Helium web-app names and URLs are shared through
`~/.config/sync/helium-apps.json`. Install an app in Helium, then run `bcp` to
capture and share it. At the end, `mac-sync` and `bcp` print
`INSTALL {NAME} WEB APP` only for apps missing on that Mac. Install those
manually in Helium; their reminders disappear on the next run. Keep the Python
helper used by these commands. See the sync manual for the full workflow.

Shared CLI tools live in `~/.config/mac-setup/packages.txt`. Ordinary
`brew install` packages stay local and temporary unless intentionally added to
that short list. Removing an entry never automatically uninstalls software.
Course C/C++ libraries run in the professor's container; project Python
libraries are installed with `uv`. See `~/.config/sync/README.md`.

Run a sync immediately with:

```sh
mac-sync
```

## Keep work running on this Mac

For T3 Code/Codex waiting for a usage-limit reset, start a local awake session
long enough to cover the wait **and** the work after it:

```sh
awake start         # 3h30m; does not open, connect, or require Tailscale
awake status
awake start 5h      # optional duration; replaces the deadline, keeps the snapshot
awake stop          # restore previous sleep settings early
```

Leave T3 Code running with its resume/retry feature enabled and keep internet
available. `awake` only prevents this Mac from sleeping; it does not schedule
T3 retries, reset Codex limits, or move work to another Mac. The display may
turn off and the screen may lock without ending the session. Do not log out
or quit T3 while waiting.

For access from another machine, use the existing VPN-aware command instead:

```sh
remote start 2h     # connects Tailscale if needed; preserves an existing session
remote status
remote stop        # restores sleep and only the VPN state remote created
```

`awake` works on battery or AC and keeps running when you unplug. `remote`
requires AC and restores settings when unplugged. Both use normal administrator
authorization at start/stop. `awake` defaults to 3h30m; `remote` keeps its 12h default. Explicit
durations include `30m`, `2h`, `1h30m`, up to 7d. Only one mode can run at a
time: stop it before switching. Logout, reboot or interrupted
startup restores the saved settings. **At timed expiry, the helper requests
native macOS sleep**; stopping early restores settings without forcing sleep.
Nothing starts automatically when plugged in. Existing VPN sessions are
untouched by `awake`; it does not disable Remote Login.

For closed-lid work on battery or AC, `awake` uses the same system sleep
override as `remote`, without its VPN dependency. Headless closed-lid operation
on Air (especially on battery) still needs a physical test; the implementation
and logic tests do not prove it. Air's November 6 timed session did record
native sleep and restoration of its previous settings; verified November 9.
Apple's documented closed-display setup uses external displays,
power, and an external keyboard/mouse or trackpad
([Apple requirements](https://support.apple.com/en-us/117373)). Start while
awake; this is not a wake-from-sleep or power-on service.

## Updates and math PDFs

On Air and Pro, `mac-update` checks every 30 minutes while awake. Once a day,
when you are actively using the unlocked Mac, it updates Homebrew formulae
and downloads app updates even for open apps. It installs queued app updates
after those apps close, without automatically quitting them. Native updaters,
App Store updates, and installers needing approval follow their own rules.
Studio has no recurring update schedule.

```sh
mac-update --status    # inspect pending versions
mac-update --dry-run  # inspect eligibility and planned work
mac-update --now      # request an extra pass with the same safeguards
```

Tectonic and Pandoc provide lightweight math PDFs without a full TeX install:

```sh
tectonic --keep-logs document.tex
pandoc document.md --pdf-engine=tectonic -o document.pdf
tectonic --only-cached document.tex  # offline after required files are cached
```

Tectonic downloads support files on first use. AMS math, theorem environments,
TikZ/PGFPlots and BibTeX are covered by `~/.config/mac-setup/latex-smoke.tex`.
LuaLaTeX, minted/Pygments and Biber may need additional tooling. Pro's math
tool rollout remains pending until it is reachable.

## Keyboard and window controls

- Right Command is the global Super key, implemented by Karabiner.
- Command/Alt/Ctrl-Space control Herdr tabs, panes, and workspaces.
- Super-M splits the current app and the last other app; press again to maximize.
- Super-F maximizes; Super-minus/plus moves the split boundary.

Hammerspoon manages windows on one desktop and needs Accessibility permission
on each Mac. Normal windows maximize when focused unless they belong to the
active split. Ghostty attaches to persistent Herdr terminal sessions; VS Code
is the editor. Codex runs through T3 Code; the terminal CLI is also available.

Fish keeps `amsc`, `sv`, `gcp`, `bcp`, `py`, `l`/`ls`, `cl`, and `keymap-docs`.
`gcp` stages, commits and pushes the current repository; `bcp` maintains the
bare dotfiles repository. The unused `nb`, `b`, `o`, and Codex stealth wrapper
were removed; use `jupyter lab`, `bat`, `open`, and the normal `codex` command.

The canonical binding inventory is `~/.config/keymaps/registry.tsv`; the
readable generated table is in `~/.config/sync/README.md`.

App Shortcuts edited in macOS System Settings > Keyboard > Keyboard Shortcuts
are shared automatically by `mac-sync`, including additions and deletions on
either Mac. They use a separate `app-shortcuts` Git branch; other macOS
Keyboard Shortcuts categories remain local. See the sync manual for details.

## Dotfile maintenance

`bcp` validates the app and keymap configuration, stages the maintained
dotfiles, then asks for a commit message and pushes. `sync-maintain` performs
the validation and staging without committing.
