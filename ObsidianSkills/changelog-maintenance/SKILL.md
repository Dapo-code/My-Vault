---
name: changelog-maintenance
description: Maintain changelog.md with concise, dated entries for meaningful vault changes. Use when files are added, moved, removed, or workflow rules are changed.
---

# Changelog Maintenance Skill

## Goal
Keep changelog.md accurate and useful as a historical audit trail.

## Required Parameters
Collect these before running this skill:

1. target_file
- `changelog.md` for non-skill changes, or `ObsidianSkills/skills-changelog.md` for skill-related changes.

2. change_scope
- Short label for what changed (for example: structure, links, skills, scripts, rules).

3. entry_lines
- One or more concise changelog lines to append.

## Optional Parameters
1. entry_date
- Date in `YYYY-MM-DD`. Defaults to today when omitted.

2. include_reason
- Boolean. Include why the change happened when true.

## Parameter Rules
1. Do not append anything if `entry_lines` is missing.
2. Route skill-related changes to `ObsidianSkills/skills-changelog.md`.
3. Keep each line to one sentence.
4. Ensure every line starts with `- YYYY-MM-DD:`.

## Target
- changelog.md under `## Entries`

## Skills Changelog
- Use `ObsidianSkills/skills-changelog.md` for skill-specific changes under `ObsidianSkills`.

## Entry Format
```md
- YYYY-MM-DD: Short summary of what changed and why.
```

## Steps
1. Validate required parameters and route `target_file` correctly.
2. Identify meaningful changes based on `change_scope`.
3. Add one concise line per meaningful update from `entry_lines`.
4. Use factual language and include intent when `include_reason` is true.
5. Avoid duplicates and vague wording.

## Policy Reminder
- Skill-Index.md must link to folder-level skill note files, not to `SKILL.md` files.
- Skill-related changes under `ObsidianSkills` belong in `ObsidianSkills/skills-changelog.md`, not the top-level changelog.

## Validation Checklist
- All required parameters were provided.
- Date uses `YYYY-MM-DD`.
- Entry is one sentence.
- Entry maps to a real, completed change.
- Entry is appended at the bottom.
- Skill changes are logged in the skills changelog, not the top-level changelog.

## Output Format
- List of newly added changelog lines.

## Related
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[ObsidianSkills/changelog-maintenance/changelog-maintenance|Changelog Maintenance Skill Note]]
