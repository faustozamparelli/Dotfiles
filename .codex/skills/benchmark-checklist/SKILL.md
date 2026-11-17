---
name: benchmark-checklist
description: Validate a benchmark, performance regression, speedup or resource comparison before relying on or reporting the number. Use automatically for measured performance claims and optimization baselines. This checks evidence; it does not start optimization or apply to every incidental number.
metadata:
  upstream: https://github.com/cursor/plugins/tree/e1cc03121a0e71129a4fb730d7c5528a0a3e43c8/pstack/skills/benchmark-checklist
  adaptation: Portable measurement checks with project-native tools; preserves scientific protocols and scales effort to the claim.
---

# Check performance evidence

State the claim being tested and inspect what the measurement command actually
times, counts and omits. Use the existing protocol and tools rather than adding
a benchmark framework.

- Confirm the intended work happened inside the measured region, completed
  successfully and produced correct outputs. Count errors, retries and completed
  work; fast rejection or skipped work is not an improvement.
- Compare realistic workloads under comparable versions, builds, data, seeds,
  concurrency, cache state and settings. Note host load and experimental changes.
  Do not choose an implementation from an accidentally untuned comparison.
- Follow the project's sampling/statistical protocol. Otherwise repeat each
  side enough to expose noise, interleaving baseline and candidate when practical;
  five runs each is a useful inexpensive starting point, not permission for ten
  expensive simulations. Report sample count and spread alongside the summary.
  Treat a difference within the variation as inconclusive.
- Investigate what limits the path before asserting why it improved. Profile
  separately from reported timing runs. Check implausible results against CPU,
  storage/network limits and the fraction of total time the changed part used.
- Tie microbenchmarks to the end-to-end path the user cares about. State units,
  workload, denominator, environment and evidence location so the claim can be
  assessed and reproduced. Keep raw runs outside Git unless the protocol requires
  them; do not generate a Markdown report without a lasting need.

A requested rough estimate may use one run if labeled provisional; still verify
that the work happened and outputs were correct. A comparative claim needs
comparative evidence. Mark missing evidence and unsupported explanations clearly.
Preserve existing scientific protocols, seeds, baselines and metric denominators.
This skill validates results; `hillclimb` owns an explicitly requested search
for improvements, and `full-stop` owns project delivery.
