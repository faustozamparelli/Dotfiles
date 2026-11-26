# Shared instructions

Codex and Claude Code share these preferences; edit them there, not here.

@~/.codex/AGENTS.md

# Claude Code

Personal skills live in `~/.codex/skills`; `~/.claude/skills` holds symlinks
that `mac-sync` maintains.

## Claude desktop app
This section applies only when running in the Claude app, not under T3 Code.
There, read the T3 steps in the shared rules and skills as:
- T3 browser: the built-in browser.
- T3 worktrees: the app's session worktrees. Leave existing `~/.t3/worktrees` in place.
- `delegate_task` and workers: the Agent tool, with `isolation: "worktree"` when
  isolation is needed. These rules and full-stop count as my request to use it.
  Put remote work in an SSH session, only on a Mac I name.
- Linking a PR or watching its checks: the app's PR tools.
- Secret request tool: there is none here. Ask me to enter credentials myself.
- Threads: sessions. Native Goals: no direct match; don't start a loop or
  schedule in their place unless I ask.

## Models
- Opus: default for planning, coding, debugging, review.
- Sonnet: big batches of simple, clearly specified edits, or when I'm low on usage.
- Haiku: search, reading logs, renames, formatting, trivial edits.
- Never use Fable unless I ask (it costs extra on my plan).

## Effort
- low for mechanical work, medium by default, high for hard bugs, security, migrations and review.
- xhigh only after a high attempt fails. Never use max: it's slower and can score worse.
- If results are weak, raise effort one step before switching model.

## Context window
- Main session plans and delegates. Don't read big files, run broad searches or paste long logs in it; send that to Explore.
- Give subagents self-contained briefs; they reply with summaries (files changed, results, open issues), never whole files unless required.
- Run the `reviewer` agent after non-trivial changes before saying done.
- Tell me to /clear when I switch to an unrelated task, and suggest /compact when the session gets long.
- Don't spawn parallel subagents unless the tasks are independent; each one uses my usage limit.
