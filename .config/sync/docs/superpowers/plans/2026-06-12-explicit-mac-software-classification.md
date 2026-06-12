# Explicit Mac Software Classification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace automatic software promotion with an editable per-Mac shared/local classification file while preserving automatic VS Code, shortcut, and Marta configuration sync.

**Architecture:** `maintain.sh` captures fresh installer-backed inventory, reconciles a per-Mac classification file, declassifies externally uninstalled shared software, generates shared desired-state lists, and installs missing shared software. The classification file is tab-separated with `[.]` and `[ ]` bracket controls. Fish `bcp` stops and opens the review file when new local software needs classification.

**Tech Stack:** Bash, Homebrew CLI, `mas`, VS Code CLI, macOS `defaults`, bare Git dotfiles repository.

---

### Task 1: Classification Reconciliation Tests

**Files:**
- Modify: `tests/test-maintain.sh`

- [x] Add a fixture for existing shared and local rows, fresh Brew/cask/App Store inventory, an externally removed shared item, and Marta.
- [x] Assert newly discovered software is rendered as local, existing installed shared software stays shared, removed software disappears, matching rows on another Mac become local, and generated shared lists exclude declassified software.
- [x] Run `bash tests/test-maintain.sh` and verify the new assertions fail against the old workflow.

### Task 2: Classification Reconciliation

**Files:**
- Modify: `maintain.sh`

- [x] Add parsing, validation, reconciliation, rendering, and declassification helpers for `review/<inventory-name>.txt`.
- [x] Capture fresh inventory before any shared installation and reconcile the current Mac.
- [x] Generate shared Brew, cask, and App Store files from validated review files.
- [x] Install missing generated shared software, refresh inventory, and preserve the review classifications.
- [x] Run `bash tests/test-maintain.sh` and verify it passes.

### Task 3: Marta Settings And Documentation

**Files:**
- Modify: `maintain.sh`
- Modify: `README.md`
- Modify: `agent.md`

- [x] Stage Marta's `conf.marco` and `favorites.marco` when present without staging its preferences plist.
- [x] Document how to edit the dot buckets, how external uninstall works, and how to run `sync-maintain`.
- [x] Update agent instructions to edit review files instead of generated shared files.
- [x] Run `bash tests/test-maintain.sh` and verify it passes.

### Task 4: Fresh Migration And Verification

**Files:**
- Create: `review/fausto-s-macbook-air.txt`
- Modify: `inventory/fausto-s-macbook-air/*`
- Modify: `shared/brew-leaves.txt`
- Modify: `shared/brew-casks.txt`
- Modify: `shared/mas-apps.txt`

- [x] Run `sync-maintain` against the current Mac's fresh installed state.
- [x] Verify Marta is present in the review file and software already uninstalled is absent.
- [x] Verify missing old shared software is declassified rather than reinstalled.
- [x] Run `bash tests/test-maintain.sh` and inspect bare Git status.

### Task 5: Bracket Controls And Safe `bcp`

**Files:**
- Modify: `maintain.sh`
- Modify: `tests/test-maintain.sh`
- Modify: `README.md`
- Modify: `agent.md`
- Modify: `~/.config/fish/config.fish`

- [x] Render and validate `[.] [ ]` shared/local controls.
- [x] Return a dedicated review-required status when new software defaults local.
- [x] Make Fish `bcp` open the review file and stop before commit/push on that status.
- [x] Document the bracket format and `bcp` review behavior.
- [x] Run automated and live idempotency verification.
