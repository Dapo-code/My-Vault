---
name: changelog-maintenance
description: Maintain changelog.md with concise, dated entries for meaningful vault changes. Use when files are added, moved, removed, or workflow rules are changed.
---

# Changelog Maintenance Skill

## Goal
Keep changelog.md accurate and useful as a historical audit trail.

## Target
- changelog.md under `## Entries`

## Skills Changelog
- Use `ObsidianSkills/skills-changelog.md` for skill-specific changes under `ObsidianSkills`.

## Entry Format
```md
- YYYY-MM-DD: Short summary of what changed and why.
```

## Steps
1. Identify meaningful changes (structure, links, skills, scripts, rules).
2. Route skill-specific updates to `ObsidianSkills/skills-changelog.md`.
3. Add one concise line per meaningful update.
4. Use factual language and include intent.
5. Avoid duplicates and vague wording.

## Policy Reminder
- Oladapo.md must link to folder-level skill note files, not to `SKILL.md` files.
- Skill-related changes under `ObsidianSkills` belong in `ObsidianSkills/skills-changelog.md`, not the top-level changelog.

## Validation Checklist
- Date uses `YYYY-MM-DD`.
- Entry is one sentence.
- Entry maps to a real, completed change.
- Entry is appended at the bottom.
- Skill changes are logged in the skills changelog, not the top-level changelog.

## Output Format
- List of newly added changelog lines.

## Related
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[Oladapo]]
