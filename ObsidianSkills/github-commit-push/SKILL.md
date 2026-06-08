---
name: github-commit-push
description: Commit and push changes with consistent safety checks and a strict prefix-based commit subject format by following the repository GitHub rules file.
---

# GitHub Commit and Push Skill

## Goal
Commit and push changes safely and consistently whenever the user asks, using a clear commit subject format.

## Required Parameters
Collect these before running this skill:

1. commit_prefix
- One of: `SKILL UPDATE`, `DOC UPDATE`, `FIX`, `CHORE`.

2. commit_summary
- Short description used after the prefix.

3. stage_mode
- `selected` or `all`.

4. push_mode
- `tracked` for `git push`, or `set-upstream` for `git push -u origin <branch>`.

## Optional Parameters
1. selected_paths
- File paths to stage when `stage_mode` is `selected`.

2. branch_name
- Required only when `push_mode` is `set-upstream`.

3. confirm_before_push
- Boolean. When true, confirm before push.

## Parameter Rules
1. Do not commit if `commit_prefix` or `commit_summary` is missing.
2. Enforce subject format `<PREFIX>: <what was updated>`.
3. When `stage_mode` is `selected`, `selected_paths` must be provided.
4. When `push_mode` is `set-upstream`, `branch_name` must be provided.

## Required Rules Reference
Always follow:
- [[rules/github-rules/github-agent-rules|GitHub Agent Commit and Push Rules]]

## Commit Subject Format
Use:
- `<PREFIX>: <what was updated>`

Preferred prefixes:
- `SKILL UPDATE` for changes under `ObsidianSkills` (especially skill files).
- `DOC UPDATE` for general note or documentation updates.
- `FIX` for bug fixes.
- `CHORE` for maintenance-only updates.

## Workflow
1. Validate required parameters.
2. Show pending state with `git status --short --branch`.
3. Stage files using `stage_mode`.
4. Commit with `<commit_prefix>: <commit_summary>`.
5. Push based on `push_mode`.
6. If `confirm_before_push` is true, confirm before running push command.

## Required Report After Push
Always report:
1. Commit hash
2. Commit subject
3. Branch pushed
4. Final status (clean or dirty)

## Validation Checklist
- All required parameters were provided.
- Commit subject follows prefix format.
- Push command succeeds.
- Branch is tracking expected remote branch.
- Post-push status is shown.

## Related
- [[ObsidianSkills/github-commit-push/github-commit-push|GitHub Commit and Push Skill Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
