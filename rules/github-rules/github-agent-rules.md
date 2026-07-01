---
title: GitHub Agent Commit and Push Rules
created: 2026-06-08
updated: 2026-06-08
scope: repository
---

# Purpose

Define a consistent and safe process for how the agent should commit and push when instructed.

# Trigger

Apply these rules whenever the user asks any variant of:
- "commit and push"
- "commit and push changes"
- "stage, commit, and push"

# Safety and Scope Rules

1. Confirm repository and branch before commit.
2. Show pending changes first with `git status --short --branch`.
3. Stage only what the user requested.
4. If request says "remaining changes", stage all with `git add -A`.
5. Never use destructive git commands unless explicitly requested.
6. Push to current tracked branch unless user specifies a different branch.

# Commit Message Structure

Use one-line subject with a single-word uppercase prefix.

Format:
`<PREFIX>: <what was updated>`

The repository `commit-msg` hook is authoritative and accepts **only** these prefixes:
`SKILL` | `DOC` | `FIX` | `CHORE` | `FEAT`. A prefix with a trailing word (e.g. `DOC UPDATE`)
will be rejected.

Examples:
- `SKILL: add github ssh setup skill and scripts`
- `SKILL: refine daily-notes SKILL instructions`
- `DOC: revise Oladapo note links`
- `FIX: correct path handling in deduplicate script`
- `FEAT: add condensed PET-AI agent rules`

# Prefix Selection Rules

1. Use `SKILL` when any `SKILL.md` or skill note is changed under `ObsidianSkills/`.
2. Use `DOC` for markdown/content changes not primarily skill logic.
3. Use `FIX` for bug fixes in scripts or automation.
4. Use `CHORE` for maintenance-only changes (formatting, renames, metadata cleanup).
5. Use `FEAT` for new capabilities (new skills, rules, scripts, or automation).

# Recommended Commit Body (when helpful)

Use for medium or large commits.

Template:

Summary:
- <bullet of major change 1>
- <bullet of major change 2>

Files:
- <key file path 1>
- <key file path 2>

Validation:
- <command run or check performed>

# Push Procedure

1. `git status --short --branch`
2. Stage files
3. `git commit -m "<PREFIX>: <what was updated>"`
4. `git push` (or `git push -u origin <branch>` if upstream is missing)
5. Report commit hash and branch pushed

# Response Format After Push

Always report:
1. Commit hash
2. Commit subject
3. Branch pushed
4. Final status (clean/dirty)

# User Confirmation Preference

If the change scope is ambiguous, ask a short confirmation question before staging.
If the user explicitly requests all remaining changes, proceed without extra confirmation.
