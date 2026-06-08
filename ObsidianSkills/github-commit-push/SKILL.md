---
name: github-commit-push
description: Commit and push changes with consistent safety checks and a strict prefix-based commit subject format by following the repository GitHub rules file.
---

# GitHub Commit and Push Skill

## Goal
Commit and push changes safely and consistently whenever the user asks, using a clear commit subject format.

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
1. Show pending state with `git status --short --branch`.
2. Stage only requested files, or stage all for "remaining changes" using `git add -A`.
3. Commit with required subject format.
4. Push to current tracked branch with `git push`.
5. If upstream is missing, use `git push -u origin <branch>`.

## Required Report After Push
Always report:
1. Commit hash
2. Commit subject
3. Branch pushed
4. Final status (clean or dirty)

## Validation Checklist
- Commit subject follows prefix format.
- Push command succeeds.
- Branch is tracking expected remote branch.
- Post-push status is shown.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
