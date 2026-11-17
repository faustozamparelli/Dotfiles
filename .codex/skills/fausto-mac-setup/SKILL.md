---
name: fausto-mac-setup
description: Operate or change Fausto's Macs, shared dotfiles, remote access, power sessions, or custom mac/awake/remote commands. Use for machine setup and routing work to Studio, not ordinary project implementation or code explanations.
---

# Mac setup

Identify the current host. Read only the sections needed for this task:

- `~/README.md` is the canonical overview: commands and tool choices, Macs and
  access, dotfiles and sync, Studio worker, and review of Studio results.
- `~/.config/sync/README.md` contains the detailed procedures. Read its **Agent
  Contract** before configuration changes, and **Machine operating reference**
  before access, power or desktop work. Follow **Project placement and handoff**
  when routing substantial work or preparing requested local outputs.
- For manifests, shortcuts, plugin/MCP toggles or existing implementation,
  follow the paths linked in those guides instead of rediscovering the setup.

Use existing commands and procedures. Preserve independent edits, user-opened
connections and machine-local credentials. Verify the result on the target Mac;
an SSH connection alone does not establish desktop or wake access.

Publish portable changes with scoped paths in the bare dotfiles repository,
then reconcile reachable Macs using its existing contract. Managed plugin
skills and runtime state stay local; personal skills are tracked explicitly.
