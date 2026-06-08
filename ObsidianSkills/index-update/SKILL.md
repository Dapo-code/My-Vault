---
name: index-update
description: Maintain Skill-Index.md as the skills index note. Use when adding, moving, removing, or renaming skills that should be discoverable from the skill index.
---

# Index Update Skill

## Goal
Keep Skill-Index.md clear, current, and scannable.

## Required Parameters
Collect these before running this skill:

1. target_path
- Changed or newly created note/skill path.

2. entry_title
- Human-readable title for the index link.

3. entry_description
- One sentence explaining what it does and when to use it.

4. change_type
- `add`, `update`, or `remove`.

## Optional Parameters
1. is_skill_related
- Boolean. Routes changelog entry to `ObsidianSkills/skills-changelog.md` when true.

2. remove_stale_entries
- Boolean. Remove outdated links when true.

3. changelog_line
- Optional dated changelog line to append.

## Parameter Rules
1. Do not modify Skill-Index.md if `target_path`, `entry_title`, or `entry_description` is missing for add/update.
2. Never add direct links to any `SKILL.md` file in Skill-Index.md.
3. Use `change_type` to decide whether to add, update, or remove an entry.
4. Route skill-related changelog updates to `ObsidianSkills/skills-changelog.md`.

## Steps
1. Validate required parameters.
2. Open Skill-Index.md and keep the opening sentence intact.
3. Keep index entries under `## Vault Skills Index`.
4. For every skill folder, link the folder-level note file (for example `deduplication-cron.md`) instead of `SKILL.md`.
5. Add or update entries using this format:

```md
- [[path/to-note|Readable Title]]
  Description: One sentence explaining what it does and when to use it.
```

6. Remove stale entries when `remove_stale_entries` is true.
7. Keep descriptions non-overlapping.
8. Append a dated line to the correct changelog file using `is_skill_related`.

## Validation Checklist
- All required parameters were provided.
- Every link in Skill-Index.md resolves to an existing file.
- Every link has one `Description:` line beneath it.
- No Skill-Index.md entry points to a `SKILL.md` file.
- No duplicate entries for the same destination.
- changelog.md has an entry for non-skill index edits.
- ObsidianSkills/skills-changelog.md has an entry for skill-related edits.

## Output Format
- Short summary of links added/updated/removed.
- Files touched list.

## Related
- [[ObsidianSkills/index-update/index-update|Index Update Skill Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
