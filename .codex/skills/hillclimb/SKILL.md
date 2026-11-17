---
name: hillclimb
description: Run explicitly requested, bounded optimization experiments against a measurable target, keeping only verified improvements. Use when invoked for sustained performance, accuracy, resource or evaluation-score improvement. Not a general implementation loop or permission to invent a quality grade.
metadata:
  upstream: https://github.com/cursor/plugins/blob/e1cc03121a0e71129a4fb730d7c5528a0a3e43c8/pstack/skills/poteto-mode/playbooks/hillclimb.md
  adaptation: Explicit-only, bounded experiments without pstack orchestration or mandatory minimum iterations.
---

# Improve a measured result

Define the target before iterating. Establish the metric and direction, realistic
workload, correctness/quality constraints, measurement command, baseline and stop
condition. Derive these from the user's request and existing project protocol;
ask only when a consequential target or tradeoff remains unresolved. A vague
request to make something better does not define an optimization objective.

Use the user's attempt, time and compute limits. Without a stated limit, run
at most three modest hypothesis attempts and report that bound before starting.
For expensive or scientific runs, use the existing approved protocol and compute
budget rather than inventing a large search. Follow Studio placement preferences.
Stop early when the target is verified, the limit is reached, evidence is missing
or further ideas are not worth their cost. Do not change the success criterion
or force extra attempts after reaching it.

1. Validate the measurement with `benchmark-checklist`. Freeze the workload,
   evaluator, splits/seeds and correctness checks for the comparison. Preserve
   a reproducible baseline and the starting code/input state.
2. Form one evidence-based hypothesis. Under `full-stop`, the coordinator owns
   the experiment and assigns one bounded implementation attempt to a worker.
   Otherwise do a modest attempt directly. Use at most one candidate at a time
   unless the user asks for a parallel comparison with an explicit resource bound.
3. Inspect the change, rerun the same measurement and correctness checks, and
   compare against the best verified result with appropriate noise handling.
   Keep the change only if it improves the best verified metric beyond noise
   and satisfies the correctness/quality constraints. An incremental improvement
   may be retained before the final target is reached. Revert only the attempt's
   own edits when rejected, preserving unrelated work. Never discard
   uncommitted input or use a blanket reset to roll back an experiment.
4. Keep a compact record of hypothesis, code/input revision, command, raw result,
   checks and keep/revert verdict in the project's existing experiment format or
   a TSV/JSON artifact outside the repo. Reuse that evidence for the final report.
   Report all attempted candidates, including failures, without selecting only
   favorable runs. Retain the best verified state at the end.

For model/evaluation scores, keep holdout data separate and preserve the metric
denominator. Do not edit the grader, test cases or rubric to improve the number;
do not substitute a model's self-awarded grade for external evidence. If evaluator
changes are the requested research, label them as a different experiment.

Native persistent Goals manage continued pursuit, not experimental validity.
Create one only when the user explicitly requests a Goal; never infer that grant
from an ordinary task or from invoking this skill. Follow an existing Goal's
lifecycle and budget without resetting it to extend the run. Do not create a
Goal just to get automatic continuations. If the request includes implementation
delivery, `full-stop` owns review and the open, unmerged PR. Report target,
baseline, best result, uncertainty, attempted/accepted counts, evidence path and
why the loop stopped. A budget limit is not proof that the target was achieved.
