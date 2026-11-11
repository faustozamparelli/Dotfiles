---
name: fausto-workflow
description: Navigate Fausto's personal Mac workflow, tools, remote access and bare dotfiles. Use when operating his Macs, changing the shared setup, or choosing the appropriate existing system tool.
---

# Fausto's workflow

Read `~/README.md` for commands, shortcuts and Mac/IP inventory. Follow
`~/.codex/AGENTS.md` and project instructions; detailed system procedures and
evidence live in `~/.config/sync/README.md`.

- **Work:** Codex through T3 Code; VS Code; Ghostty → Herdr → fish. Prefer
  native terminal/file and available T3 browser/thread/secret tools. Discover
  callable tools and load relevant artifact/plugin skills per session.
- **Projects:** Python via `uv`/project `.venv`, including notebook kernels;
  course C/C++ via OrbStack's `amsc` and `~/shared-folder`; engineering extras on
  Pro; math PDFs via Tectonic/Pandoc. Reuse existing recipes/toolchains.
- **Power:** `awake start [duration]` defaults to 3h30m on battery/AC without
  touching Tailscale; `remote start [duration]` defaults to 12h on AC with VPN
  management. Both have `status`/`stop`, one shared session and native-sleep
  expiry. T3 owns retries; keep it running and online. Closed-lid battery work
  and limit-reset resumption remain unverified.
- **Access:** Identify the current Mac first; prefer `studio` for remote work.
  Follow AGENTS.md's SSH routes. Laptop Tailscale is normally off; preserve
  user-opened connections and restore agent-opened Air state. Wake recovery
  and UI control require evidence beyond SSH.
- **Publish:** Fish's `bare` is an alias. In other shells use
  `git -C "$HOME" --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" …`.
  `mac-sync --check` inspects; `mac-sync` applies local configuration;
  `mac-sync --pull` receives incoming configuration. `sync-maintain`/`bcp` may
  install/stage broadly. Use scoped paths and AGENTS.md's check/publish/reconcile
  rules; preserve independent edits and keep credentials/runtime state local.

Tool inventories: `~/.config/mac-setup/` for CLI/app/machine manifests,
`~/.config/keymaps/registry.tsv` for keys, `~/.config/sync/` for extensions,
reviewed preferences and `codex-technical.json` (plugins/MCPs/per-Mac overrides).
Use its helper's `set-mcp`/`set-plugin`; app MCPs need their local bridge.
Track this custom skill; leave managed skills/caches local. Keep command details
in the guide and operational evidence in the existing manual.
