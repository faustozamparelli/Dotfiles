---
name: diagnosing-bugs
description: Find the cause of a difficult, intermittent, recurring or unclear bug, including performance regressions. Use when a failure needs reproduction, bisection, targeted instrumentation or competing hypotheses. Skip this extra process for obvious small fixes. full-stop owns subsequent project delivery.
metadata:
  upstream: https://github.com/mattpocock/skills/tree/5863806dd4e15c63174bee4e7515a4256792ecfa/skills/engineering/diagnosing-bugs
  adaptation: Focused diagnosis with existing project tools; no ticket, glossary, browser package or helper-script dependency.
---

# Diagnose a hard bug

Build the shortest useful feedback loop that distinguishes the user's failure
from correct behavior. Read the relevant source and available evidence to design
it; do not guess a fix and treat a passing generic test as proof.

1. Capture the exact symptom and a command or interaction that reaches it.
   Prefer the project's tests, CLI, HTTP tools or built-in browser. Minimize the input
   and steps while confirming that the original failure still occurs. Preserve
   versions, fixtures, time and seeds where they affect reproduction. For flaky
   failures, record failures per attempt and probe what changes that rate.
2. State the leading explanations and what observation would distinguish them.
   Test a targeted prediction at a time. Use bisection, a debugger, a profiler or
   narrow temporary instrumentation when it answers a concrete question. Keep
   unsuccessful hypotheses in a compact working summary, not a new repo document.
3. Confirm the causal explanation against the original scenario. Turn the
   reproduction into a focused regression test when the project has a suitable
   seam; ensure the check exercises the real failing caller path. Apply the
   smallest supported fix and rerun both the focused check and original scenario.
4. Remove temporary instrumentation and scratch probes unless they have an
   explicit lasting use. Report the cause, reproduction, before/after evidence
   and any remaining uncertainty. Let `full-stop` handle integration and the PR.

For performance symptoms, establish the workload and baseline before changing
code; use `benchmark-checklist` for claims about improvement. A diagnostic probe
may be disposable; keep user data, credentials and unrelated edits intact.
Put large logs and traces in an existing output location or outside the repo,
and share only the relevant redacted evidence.

If the failure cannot be reproduced, distinguish that from a disproven bug.
Report what was tried and the smallest missing input or access needed. Do not
invent certainty or keep making speculative patches. After two failed fixes
based on the same assumption, revisit the assumption rather than extending it.
Under a coordinator, keep this investigation in one bounded worker and return
the evidence and result; do not start nested agents.
