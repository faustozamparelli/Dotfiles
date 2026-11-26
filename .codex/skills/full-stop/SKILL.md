---
name: full-stop
description: Complete substantive project changes through implementation, verification and an open PR for Fausto to review and merge. Use for features, fixes, refactoring, or preparing an existing PR for review. Excludes read-only explanations, trivial edits and Mac dotfiles publication. Never merge under this workflow.
metadata:
  upstream: https://github.com/t3dotgg/tstack/tree/11e37a74d0a6868c121cd0910ab2b3bd9873b92a/skills/full-stop
  adaptation: Personal delivery workflow with PR writing delegated to file-pr.
---

# Full stop

Own the requested change through an open PR with evidence that it works.
Fausto reviews and decides when to merge. This workflow never merges, enables
auto-merge, enters a merge queue or pushes changes to the default branch.
It grants no additional permission for unrelated work or production operations.

1. **Establish the scope.** Read repository instructions and inspect the branch,
   working tree and existing PR. Preserve unrelated changes. Reuse the task's
   checkout and PR where appropriate; create a task branch if on the default
   branch. Use a separate Git worktree when isolation is needed. Follow Fausto's
   Studio placement preference before substantial execution. Derive observable
   acceptance checks from the request and settle the relevant architecture and
   interfaces before assigning implementation. Before working
   on an existing PR, disable auto-merge/remove it from a merge queue if set,
   and report doing so. If that cannot be done, stop before a push could merge it.
2. **Implement.** Make the smallest maintainable change that satisfies the
   request. Explain consequential choices briefly, then proceed autonomously.
   Use the coordinator/worker procedure below for substantial work. Keep
   documentation edits limited to the global documentation policy. Update
   affected commands, examples and user-facing behavior where readers
   already look for them, and check the guidance against the final change.
3. **Verify.** Reproduce a bug when practical and recheck the same case after
   the fix. Run the relevant repository checks and inspect their outputs.
   Check actual runtime behavior when static or mocked checks cannot establish
   it. Add focused regression coverage when warranted. Report unavailable,
   pre-existing or failing checks honestly; do not call an unverified change
   ready. Recheck behavior changes and meaningful conflict fixes.
4. **Review the final diff.** Check callers, scope, unintended behavior and
   unnecessary complexity. Fix supported problems. When the harness provides
   a read-only reviewer agent (Claude Code: `reviewer`), run it once on
   non-trivial diffs; it is one pass, not a review loop. Address existing
   review findings with a fix or a concrete reason for disagreeing.
5. **Prepare the PR.** Commit and push only task paths. Read and apply
   `file-pr` when drafting, opening or updating the PR, even when the
   user asked for implementation without explicitly asking for a PR.
   Keep unrelated changes out and split oversized work when useful. Do not
   rewrite published history just to polish it. Use `--force-with-lease` only
   for an authorized rewrite of this task's branch. Bind the PR to the session with
   the app's PR tools right after creating or pushing it.
6. **Resolve outstanding checks.** Inspect the live PR's head, base, checks,
   reviews and mergeability. Check again before each push that the PR cannot
   merge automatically. Fix relevant CI and review problems. When waiting for
   checks or reviews, rely on the app's PR monitoring and end the turn; resume
   when notified, without polling.
7. **Hand back the result.** Verify the final PR state. Report the PR link, final head, checks, review state
   and remaining risks. Distinguish ready for Fausto's review, waiting for
   required approval, and blocked. Leave the PR open and unmerged.

If there is no remote, PR facility or sufficient access, complete the local
work and verification and report the exact blocker and branch. Ask only for
the consequential information or access needed to continue; never invent a PR
or approval. Ask Fausto to enter credentials that only Fausto can provide.

## Coordinator and workers

For substantial implementation, delegate one bounded implementation task at
a time. The main thread owns requirements, architecture, interfaces, integration
and the final PR review. Read enough source to judge the approach; leave bulk
exploration, low-level implementation and verbose check output with the worker.
Do small or tightly coupled edits directly when delegation adds more cost than
it saves. Use at most two simultaneous workers, only for independent scopes;
do not create a reviewer panel or workers that spawn their own agents.

Give each worker a short brief with the goal, acceptance checks, relevant file
pointers, owned paths, interface constraints, non-goals and validation commands.
Start without the full parent transcript when supported. Ask for a concise
handoff: what changed, exact checkout/branch and commit if any, checks and their
results, evidence locations, unresolved decisions and risks. Keep raw logs out
of the main thread. Tell the worker not to push, open PRs or start other agents.

Workers are subagents. Pick their model per the global model routing. Only one
writer may own a file at a time; do not edit the worker's files while it runs.
Give concurrent writers their own worktrees and integrate their changes in the
main thread. Wait for a worker's completion notice rather than polling. Keep
lightweight work local; route substantial project work per the Mac placement
policy.

Inspect the actual diff and important outputs when the worker finishes. Check
the implementation against the architecture, caller contracts and acceptance
checks, as if reviewing someone else's PR. A worker's summary is not proof.
Give concrete corrections; use a fresh worker when the direction or task changes,
and resume an existing one only when preserving its state saves meaningful work.
Cancel and confirm a running delegate has stopped before replacing it. Fix small findings yourself rather
than spawning another review. After two unsuccessful implementation attempts on
the same approach, stop respawning and re-examine the premise or missing evidence.
Integrate and verify the final result before filing the PR.

Use `diagnosing-bugs` for unclear, intermittent or recurring failures, and
`benchmark-checklist` before relying on measured performance claims. Ordinary
tasks end at their acceptance checks. Never convert a normal task into an unbounded
loop, schedule or optimization run unless the user asks. Explicit sustained optimization uses `hillclimb`.
