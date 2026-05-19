---
name: open-changes
description: Opens files changed in the current working tree in VS Code. Use when the user wants to review files pi just edited, especially via /skill:open-changes.
---

# Open Changes

When this skill is invoked, open the changed files in VS Code without ending the pi session.

## Procedure

1. Run the helper script from the current working directory:

```bash
~/.pi/agent/skills/open-changes/scripts/open-changes.sh
```

2. Tell the user which files were opened, or that no changed files were found.

The script uses Git when available:
- modified/staged files from `git diff --name-only` and `git diff --cached --name-only`
- untracked files from `git ls-files --others --exclude-standard`

If the directory is not inside a Git repository, the script falls back to recently modified files under the current directory.
