---
name: full-stop
description: Complete substantive project changes through implementation, verification and an open PR for Fausto to review and merge. Use for features, fixes, refactoring, or preparing an existing PR for review. Excludes read-only explanations, trivial edits and Mac dotfiles publication. Never merge under this workflow.
metadata:
  upstream: https://github.com/t3dotgg/tstack/tree/11e37a74d0a6868c121cd0910ab2b3bd9873b92a/skills/full-stop
  adaptation: Self-contained personal workflow; no full-send, sol-loop, file-pr or babysit-pr dependency.
---

# Full stop

Own the requested change through an open PR with evidence that it works.
Fausto reviews and decides when to merge. This workflow never merges, enables
auto-merge, enters a merge queue or pushes changes to the default branch.
It grants no additional permission for unrelated work or production operations.

1. **Establish the scope.** Read repository instructions and inspect the branch,
   working tree and existing PR. Preserve unrelated changes. Reuse the task's
   checkout and PR where appropriate; create a task branch if on the default
   branch. Use T3-managed worktrees when isolation is needed. Follow Fausto's
   Studio placement preference before substantial execution. Before working
   on an existing PR, disable auto-merge/remove it from a merge queue if set,
   and report doing so. If that cannot be done, stop before a push could merge it.
2. **Implement.** Make the smallest maintainable change that satisfies the
   request. Explain consequential choices briefly, then proceed autonomously.
   Keep documentation edits limited to the global documentation policy.
3. **Verify.** Reproduce a bug when practical and recheck the same case after
   the fix. Run the relevant repository checks and inspect their outputs.
   Check actual runtime behavior when static or mocked checks cannot establish
   it. Add focused regression coverage when warranted. Report unavailable,
   pre-existing or failing checks honestly; do not call an unverified change
   ready. Recheck behavior changes and meaningful conflict fixes.
4. **Review the final diff.** Check callers, scope, unintended behavior and
   unnecessary complexity. Fix supported problems. Independent model review
   is optional when requested, not a mandatory review loop. Address existing
   review findings with a fix or a concrete reason for disagreeing.
5. **Prepare the PR.** Commit and push only task paths. Open or update the PR
   with the problem, resulting behavior, relevant checks and material limits.
   Keep the description brief; add reviewer entry points for a complex diff.
   Keep unrelated changes out and split oversized work when useful. Do not
   rewrite published history just to polish it. Use `--force-with-lease` only
   for an authorized rewrite of this task's branch. Link the PR to T3 as the
   next tool call after creating or pushing it.
6. **Resolve outstanding checks.** Inspect the live PR's head, base, checks,
   reviews and mergeability. Check again before each push that the PR cannot
   merge automatically. Fix relevant CI and review problems. If waiting for
   checks or reviews in T3, register
   `watch_pull_request` and end the turn; resume when notified, without polling.
7. **Hand back the result.** Verify the final PR state. Before final handoff,
   remove any PR watch. Report the PR link, final head, checks, review state
   and remaining risks. Distinguish ready for Fausto's review, waiting for
   required approval, and blocked. Leave the PR open and unmerged.

If there is no remote, PR facility or sufficient access, complete the local
work and verification and report the exact blocker and branch. Ask only for
the consequential information or access needed to continue; never invent a PR
or approval. Use T3's secret request tool for credentials only the user can give.
