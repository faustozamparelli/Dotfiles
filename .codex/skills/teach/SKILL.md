---
name: teach
description: Explain a codebase, subsystem, change, or technical concept so Fausto can understand and work with it. Use for how it works, why it was designed that way, walkthroughs, and study requests. This is explanation, not implementation or repository documentation maintenance.
metadata:
  upstream: https://github.com/cursor/plugins/tree/e1cc03121a0e71129a4fb730d7c5528a0a3e43c8/pstack/skills/teach
  adaptation: Self-contained personal workflow; includes implementation and historical investigation without other pstack skills.
---

# Teach

Explain the subject at the depth the question needs. Use the conversation to
understand the reader's background and purpose; do not quiz them or assume
they are a senior engineer. State a reasonable interpretation and investigate
when the scope is broad.

- **How:** read the relevant source, callers and tests. Trace a concrete example
  through the system and explain what each part contributes. Link the important
  files or symbols instead of listing every function.
- **Why:** investigate the commits and PR discussions behind the decision.
  Cite recorded reasons, label your own inferences and say when the history
  does not answer the question. Do not present a plausible explanation as
  established intent. Research history only when it helps answer the request.
- Combine these approaches when both are needed. Do the investigation directly;
  this skill does not require subagents or additional skills.

Lead with a plain definition and the main answer. Explain unfamiliar terminology
where it first matters, connect it to the actual code and build on one consistent
set of names. Use examples or a diagram when they make the mechanism clearer.
Give a complete answer at the requested depth, with room for follow-up.
Preserve qualifications supported by the evidence while removing filler.

Keep the explanation in conversation. If asked for study notes, save the Markdown
outside the repository at the requested location; otherwise use
`~/Documents/Study/<project>-<topic>.md`, choosing a new name if it already exists.
Identify the source checkout and commit, and relevant uncommitted changes, so
the notes can be understood later. Repository documentation follows the global
documentation policy and needs a separate, lasting purpose.
