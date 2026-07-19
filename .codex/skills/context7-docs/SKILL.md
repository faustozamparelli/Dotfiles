---
name: context7-docs
description: Fetch up-to-date documentation and code examples for any library, framework, SDK, CLI tool, or cloud service. Use whenever the user asks about a specific library, including React, Next.js, Prisma, Express, Tailwind, Django, Spring Boot, API syntax questions, configuration options, version migration issues, library-specific debugging, setup instructions, and CLI tool usage. Prefer this over web search for library documentation because training data may not reflect recent API changes or version updates.
---

# Context7 Documentation Lookup

Retrieve current documentation and code examples from Context7 using the `resolve-library-id` and `query-docs` tools.

## Workflow

1. Resolve the library ID unless the user supplies a Context7 ID in `/org/project` or `/org/project/version` format.
   - Call `resolve-library-id` with the library name and the user's question.
   - Pick the best match by prioritizing official sources, exact name matches, high snippet counts, and high benchmark scores.
2. Query the docs.
   - Call `query-docs` with the chosen library ID and the user's question.
   - If the first result is insufficient, retry with `researchMode: true`.
3. Answer from the documentation.
   - Cite the Context7 library ID used.
   - Include directly relevant code examples when useful.
   - State clearly when you are making an inference beyond the returned snippets.

## Constraints

- Do not call either Context7 tool more than 3 times per user question.
- Do not pass API keys, passwords, credentials, personal data, or proprietary code as the `query` argument because it is sent to the Context7 API.
- If Context7 authentication fails, mention that it uses the `CONTEXT7_API_KEY` environment variable and that a key can be obtained from `https://context7.com/dashboard`.
