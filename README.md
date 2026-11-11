# Fausto's workflow

A small, living guide to this Mac setup. Detailed procedures and validation
history live in `~/.config/sync/README.md`; agent rules live in
`~/.codex/AGENTS.md`. Agents can use `$fausto-workflow`
(`~/.codex/skills/fausto-workflow/SKILL.md`) for a compact orientation.

## Daily work and tools

| Work | Tools and conventions |
| --- | --- |
| Coding agents | **T3 Code → Codex**; select the project/workspace there. Use available native browser/thread tools; the Codex CLI remains installed. |
| Editing and terminals | **VS Code** (`code .`); **Ghostty → Herdr → fish**. Detaching preserves server processes; reboot does not. Terminal editor: `nano`. |
| Search and Git | `rg`, `fd`, `bat`, `eza`, `fzf`, `z`/`zi` (zoxide), `git`, `gh`. |
| Python/notebooks | `uv sync`, `uv run …`, Ruff/Pyright; JupyterLab or VS Code with the project's `.venv` kernel. Jupytext pairing is opt-in; dependencies stay per-project. |
| Course C/C++ | OrbStack's Linux `amsc` container; projects under `~/shared-folder`. VS Code's clangd bridge/Dev Containers use its toolchain. |
| Pro engineering | QGIS, ParaView, Blender, SolidCraft, `openfoam2306`; setup/debugging in the detailed manual. |
| Math PDFs | `tectonic --keep-logs document.tex`; `pandoc document.md --pdf-engine=tectonic -o document.pdf`. First use downloads support files; `--only-cached` checks offline Tectonic compilation. |
| Desktop/web | Karabiner, Hammerspoon, Raycast, Wispr Flow, Helium web apps. Sign-ins and privacy permissions stay local. |
| Agent artifacts | Document/PDF/spreadsheet/presentation/visualization skills. Discover current callable tools; plugins/MCPs vary by Mac and app bridges. |

## Keep work running

| Command | Purpose | Default / power |
| --- | --- | --- |
| `awake start [duration]` | Local work; leaves Tailscale untouched | **3h30m**, battery or AC; unplugging does not stop it |
| `remote start [duration]` | Keep awake and connect Tailscale for remote access | **12h**, AC only; unplugging restores settings |

Use `awake status` / `awake stop` or `remote status` / `remote stop`.
Durations accept `30m`, `5h`, `1h30m` (1s–7d); starting again resets the deadline.
One mode at a time; start/stop need administrator authorization. **Expiry
requests native sleep**; stop restores settings without forcing sleep.

For T3 limit-reset retries, leave T3 running, its resume/retry enabled, and
internet available; include both the wait and subsequent work in the duration.
T3 owns resumption. Lock/display sleep is fine; logout/reboot ends the session.
Closed-lid battery work and T3 limit-reset resumption still need verification;
one Air expiry/sleep/restoration passed. Neither command wakes a sleeping Mac.

## Macs and access

Account/home: `faustozamparelli`, `/Users/faustozamparelli`; DNS suffix:
`tailed8082.ts.net`. Identify the current host first; prefer Studio remotely.

| Name / SSH alias | Tailscale IP | Role |
| --- | --- | --- |
| `studio` | `100.95.1.50` | Preferred remote host |
| `air` / `air-ts` | `100.82.17.2` | Minimal shared setup |
| `pro` / `pro-ts` | `100.122.185.114` | Shared setup plus engineering tools |

Check `/usr/local/bin/tailscale status`; probe with
`ssh -o BatchMode=yes -o ConnectTimeout=5 studio true`. `~/.ssh/config` also
provides Bonjour fallbacks `air-lan`/`pro-lan`; follow AGENTS.md's route checks.
Send remote scripts through `ssh -o BatchMode=yes studio /bin/sh -s`;
remote PATH may need `/opt/homebrew/bin`.

Laptop Tailscale is normally off. Preserve user-opened VPN sessions; restore
agent-opened Air state. Wake recovery is unverified. Desktop control additionally
needs a console login and privacy permissions; SSH alone is insufficient.

## Dotfiles, apps and sync

The private bare repository is `~/.config/git/dotfiles`, with `$HOME` as its
work tree. Fish's `bare` alias targets it; it is **not** a standalone executable.
Other shells/agents use `git -C "$HOME" --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" …`.

| Occasion | Command | What it bundles |
| --- | --- | --- |
| Inspect or diagnose | `mac status` | Startup jobs, update results, app/package drift, extension state and manual steps |
| Receive changes | `mac sync` | Fast-forward clean dotfiles, apply setup, exchange menu shortcuts and extension choices |
| Publish configuration changes | `mac save` | Capture/apply, exchange data, validate, stage, commit and push |
| Request software updates | `mac update` | Existing updater safeguards: download while open, install after closing |

Each bundle ends with `ACTION REQUIRED` or `ROUTINE COMPLETE` and saves its
latest transcript, including failures, in `~/Library/Logs/mac-routines/`.
Unresolved detectable manual steps repeat until cleared. `mac status` is read-only
and can return nonzero for reported problems. `mac sync` stops on dirty/staged
files or a failed pull. `mac save` stages broadly; review unfinished work first.
It does not pull or upgrade installed software.

`bare` stays plain Git; `bcp` remains compatible. `sync-maintain` and `mac-sync`
are lower-level setup tools, not extra daily steps. `mac-app firefox` installs,
shares and publishes an app choice; `gcp` saves the current ordinary repository.

`bcp`/`gcp` stage broadly. Agents stage task paths, check, commit/push and
reconcile reachable Macs while preserving independent edits. Keep secrets,
accounts, caches and runtime state out of Git. `mac-sync --nuke` removes
uncurated formulae; use deliberately.

Apps are shared by default; Air stays minimal. `mac-app local …` adds Pro/Studio
extras; `skip` excludes; `share` promotes; `remove` records retirement. Global
retirement also removes obsolete config/helpers and retains the retirement row.
CLI tools are shared only through `packages.txt`; other `brew install` stays local.

Login/hourly sync exchanges macOS **App Shortcuts** on a separate Git branch
and checks manifests; it does not pull executable config or install apps.
Air/Pro's `mac-update` checks every 30 minutes while awake: one active daily pass
upgrades formulae/downloads app updates; queued apps install after closing.
Use `--status`, `--dry-run`, `--now`. Studio has no schedule; native/App Store/
privileged updates have separate rules.

Only reviewed app preferences are shared. Helium shares web-app names/URLs;
install missing web apps manually when prompted. Use `helium-extension add/remove ID`
(or a store URL) for shared extension choices; `list` inspects them. Manual
sync/save exchanges the private `helium-extensions` data branch; later command
timestamps win, with offline edits and removals retained. Policy changes need
administrator authorization; policy alone does not prove a completed download.
Install TwitchNoSub manually on each Mac. Browser sessions and extension data
stay local. No extension watcher or new maintenance timer is installed.

## Shortcuts

| Keys | Action |
| --- | --- |
| Right Command | Super (Karabiner); `§` holds Wispr Flow dictation |
| Super-M | Toggle current/last app on the same display between split and maximized; Super-minus/plus moves the boundary |
| Ctrl-Option-H/L | Send the focused window to the previous/next display, including Sidecar; wraps around |
| Ctrl-Option-B | Toggle optional physical-monitor DDC brightness keys; off by default, excludes Sidecar |
| Ctrl-h/l | Previous/next Herdr workspace |
| Cmd-h/l; Cmd-t/w | Previous/next Herdr tab; new tab / close pane |
| Cmd-b/n; Alt-h/j/k/l | Split right/down; focus panes (add Shift to resize) |
| Cmd-g; Ctrl-Space ? | Herdr Codex tab; searchable Herdr keymap |
| Tab / Shift-Tab / Ctrl-r | Fish fuzzy completion / native completion / history search |

Screens are ordered left to right in macOS Display Settings (top to bottom when
vertically aligned), supporting the built-in display and two externals. Moved
windows maximize; moving a split member releases its neighbor. Super controls
the split toggle and boundary. Optional brightness keys follow the focused
physical monitor; Shift gives smaller steps. Pro has the 85 KB
`m1ddc` CLI; install it elsewhere with `brew install m1ddc` only when wanted.
No extra app is used, and no brightness listener/helper runs while the mode is off.
DDC/CI support depends on the monitor/connection; physical-monitor writes still
need a live check. **Sidecar brightness uses the iPad's own Control Center.**
Portrait Sidecar requires an additional virtual-display stream, such as
BetterDisplay Pro, running while used; the detailed manual has researched options
and limitations. No portrait app is installed.

Window automation requires Hammerspoon Accessibility permission. The complete
keymap is `~/.config/keymaps/registry.tsv`; update implementation and registry
together, then run `keymap-docs` and `keymap-docs --check`.
Fish also keeps `l`/`ls`, `py`, `cl`, `sv` (activate `.venv`) and `keymap-docs`.

## Where to look

- Apps, CLI tools, per-Mac extras/skip lists: `~/.config/mac-setup/{apps.tsv,packages.txt,machines/}`; removals: `retired-apps.tsv`.
- Fish, terminal, windows, keys: `~/.config/{fish,ghostty,herdr,karabiner,keymaps}/`, `~/.hammerspoon/init.lua`.
- VS Code: `~/Library/Application Support/Code/User/`; extension lists: `~/.config/sync/vscode-{extensions,disabled-extensions}.txt`.
- Shared preferences, web apps, agent tool choices: `~/.config/sync/{app-preferences,helium-apps,codex-technical}.json` and matching Python helpers. Use `codex-technical.py set-mcp` / `set-plugin` for local toggles; credentials remain local.
- Full procedures, limitations and evidence: `~/.config/sync/README.md`, `~/.codex/AGENTS.md`. Select relevant checks from `~/.config/mac-setup/justfile` (`just --justfile ~/.config/mac-setup/justfile check` runs the suite).

## New Mac bootstrap

Sign in to the Mac App Store. Install Homebrew, authenticate, then check out:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install git gh
gh auth login
gh auth setup-git
mkdir -p "$HOME/.config/git"
git clone --bare https://github.com/faustozamparelli/Dotfiles.git "$HOME/.config/git/dotfiles"
git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" checkout
~/.config/sync/install-agent.sh
```

If checkout conflicts, move only the listed stock files aside and retry.
Finish the detailed manual's **New Mac** steps (Herdr service, fish login shell,
sign-ins and privacy permissions). Keep this guide short; add mechanics and
validation evidence to the existing detailed manual.
