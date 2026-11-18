---
name: file-pr
description: Write or revise pull request titles and descriptions. Use automatically when drafting, opening, or updating a PR, including PR delivery as part of full-stop.
metadata:
  upstream: https://github.com/t3dotgg/tstack/tree/11e37a74d0a6868c121cd0910ab2b3bd9873b92a/skills/file-pr
---

# File PR

Check for an existing PR on the branch and review the diff against its actual
base. Use the repository's PR template and title conventions, checking recent
merged PRs or commit history if needed.

Write a concise title that names the outcome a reviewer cares about. Lead with
the problem the change solves and who or what it affects. Explain the new
behavior in plain language and mention implementation details only when they
help a reviewer understand the decision or navigate the diff.

Include the checks that support the change and any material limitations. For
measured performance, use `benchmark-checklist` and state the comparator,
conditions and sample count. Link to existing evidence or a useful entry point
when it helps the reviewer. Keep model, harness and agent attribution out of
the title and description. Check for secrets and private details before posting.

For an authorized PR update, edit the existing PR in place. When opening a PR,
default to ready for review unless a draft is requested or appropriate. Use
`gh` or the host tool. If `gh pr create` hits the GraphQL rate limit, use the
GitHub REST API to create the PR. Verify the live title, body and branch after
publishing.
