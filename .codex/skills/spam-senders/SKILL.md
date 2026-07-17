---
name: spam-senders
description: Find Gmail senders from user-provided names, move all matching messages to Spam, remove them from the inbox, and verify the cleanup. When invoked without sender names, scan the inbox and recommend likely annoying promotional or newsletter senders for the user to select. Use when the user asks to nuke, spam, suppress, or remove every Gmail message from named brands, newsletters, promotional accounts, or sender addresses.
---

# Spam Senders

Use the connected Gmail tools to process the sender names supplied by the user.

## Empty-input recommendation mode

When no sender names are supplied, inspect all Inbox mail, following pagination until exhausted. Review promotional and newsletter-like traffic, including senders that recur frequently or have multiple unread messages.

1. Group candidates by exact sender address and show the display name, address, total Inbox message count, and a representative subject.
2. Prioritize commercial promotions, newsletters, marketing automation, product-update mail, and event invitations. The user prefers a strict inbox, so include borderline marketing candidates.
3. Exclude personal correspondence, receipts, orders, bookings, security alerts, payment notices, account verification, school or work mail, and service-critical updates unless the user explicitly asks to include them.
4. Present a concise shortlist only. Do not modify any messages in this mode.
5. Ask the user which candidates to process, then use the workflow below.

## Workflow

1. Confirm Gmail access with the Gmail profile tool when access is uncertain.
2. Search each supplied name separately with `-in:trash -in:spam`, returning enough recent message metadata to identify the exact sender address.
3. Resolve names to sender addresses from the `From` field. Search broader name fragments when an exact phrase has no result.
4. Treat a match as confirmed when the display name, domain, subjects, and snippets clearly identify the requested provider.
5. Do not act on unrelated keyword matches. Report names with no match. Ask before acting only when multiple plausible senders remain ambiguous.
6. Search every confirmed address or narrowly scoped provider domain with Gmail `from:` syntax. Include Inbox, archived mail, and existing categories; exclude Trash. Follow every pagination token so all occurrences are collected.
7. Move all collected message IDs to Spam by adding the Gmail system label `SPAM`. Remove `INBOX` and `TRASH` when necessary. Process IDs in supported batch sizes.
8. Verify with an `in:spam` search for the confirmed senders. Compare the verified total with the unique collected-message total.
9. Report the total moved, the matched sender addresses or providers, unmatched names, ambiguous names left untouched, and any failures.

## Guardrails

- Interpret “all occurrences” as every Gmail message from the confirmed sender, not only promotional-category or unread mail.
- Warn before including obviously transactional, security, payment, booking, or account-verification mail unless the user explicitly requested every message from that provider.
- Never include unrelated messages merely because a provider name appears in their body, recipient field, or quoted text.
- Never claim that marking mail as Spam permanently blocks a sender. State that it can help Gmail classify future mail but does not create a guaranteed block or filter.
- Do not permanently delete messages unless the user explicitly requests irreversible deletion.
