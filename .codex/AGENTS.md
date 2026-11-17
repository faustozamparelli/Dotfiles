# Fausto's preferences

- Prefer simple, readable, maintainable changes. Reuse existing tools and architecture; avoid unnecessary dependencies, abstractions and infrastructure.
- Handle authorized work and routine choices independently. Ask only about consequential unresolved decisions. Explain substantial design choices briefly before implementation.
- Start with repository instructions, pinned versions, source and nearby tests. Use official documentation when local evidence is insufficient, version details are uncertain or research is requested.
- Use native files/terminal, app-specific CLIs and MCPs first. Use computer use only when those cannot perform the task. For browser work use T3's browser tools. Avoid unnecessary tool discovery, screenshots and skill loading.
- Work through T3 Code; do not add dependencies on the retired ChatGPT desktop app. Desktop fallback is Peekaboo (`studio-desktop` / `pro-desktop`); prefer text-only UI inspection and verify actions from fresh state.
- Be concise and concrete. Explain outcomes, important choices and limitations. Reuse living documentation; avoid extra planning/history files.
- Run relevant checks and inspect important outputs. Distinguish requirements, assumptions and measured findings; report failures and unverified behavior. Preserve scientific protocols, seeds, baselines and metric denominators.
- Keep credentials and runtime state machine-local. Preserve unrelated edits. Do not add periodic maintenance jobs.
- For Mac work: identify the host; prefer `studio` remotely. SSH/file transfers and available desktop automation are authorized. Studio stays online; laptop Tailscale remains manual. Read the operating reference before changing access or power.
- After Mac configuration/documentation changes, check, commit and push scoped portable changes to the bare dotfiles repository automatically, then reconcile reachable Macs without overwriting their edits. Report publication or rollout failures.

- From Pro/Air, default substantial project work (long agent runs, builds, tests, simulations, data processing or expensive computation) to Studio when reachable and sufficiently free. Keep quick questions, Mac-specific fixes/installations/configuration and tasks whose requested output must be created on the caller on that Mac; explicit user placement wins. Check linked T3 environments, active work and repository state before routing. Continue an existing Studio thread for the same task; use T3 delegation for remote execution when appropriate, and create a top-level thread only when the user requests one. Never silently start heavy work locally if Studio is unavailable; report that and proceed only with independent lightweight work.
- Keep full projects, datasets and heavy outputs on Studio. Review through the Studio T3 environment or VS Code Remote SSH using the exact checkout/worktree; copy only requested deliverables. For project handoffs, give the host, exact checkout/branch, changed and untracked files, output paths, relevant check results, and runnable command or preview/port with stop instructions when applicable. Prefer an existing report as the entry point; preserve scientific protocols, raw evidence and provisional-result labels.

# Where to look

- `~/README.md`: commands, shortcuts, Mac/IP inventory and common workflows (`mac status/sync/save/update`, `awake`, `remote`).
- `~/.config/sync/README.md`: detailed procedures/evidence; **Machine operating reference** for SSH, power and desktop control; **Agent Contract** for dotfiles/keymap changes. Read relevant sections, not the whole manual.
- `~/.config/sync/codex-technical.json`: shared tool choices and per-Mac overrides; `codex-technical.py set-mcp/set-plugin/set-feature NAME on|off` changes local toggles. Authentication stays local; app MCPs require their app bridge.
- `~/.config/mac-setup/`: app/package manifests and explicit installers. `~/.config/keymaps/registry.tsv`: shortcut source of truth.
- `~/Developer`: Studio projects. Use T3-managed worktrees and report exact result paths. Inspect unpublished work, linked worktrees and active T3 jobs before project cleanup.
- Bare Git: `git -C "$HOME" --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME" ...`; fish's `bare` is only an alias.
