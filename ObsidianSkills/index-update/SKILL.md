---
name: index-update
description: Maintain ObsidianSkills/skill-list.md as the canonical skills index note. Use when adding, moving, removing, or renaming skills that should be discoverable from the skill index.
---

# Index Update Skill

## Goal
Keep ObsidianSkills/skill-list.md clear, current, and scannable.

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
1. Do not modify ObsidianSkills/skill-list.md if `target_path`, `entry_title`, or `entry_description` is missing for add/update.
2. Every skill entry in ObsidianSkills/skill-list.md must include both a folder-level note link and a SKILL definition link.
3. Use `change_type` to decide whether to add, update, or remove an entry.
4. Route skill-related changelog updates to `ObsidianSkills/skills-changelog.md`.

## Mode Selector
- `fast`: Single clear add/update/remove with complete parameters.
- `standard`: Minor ambiguity in title, path, or changelog routing.
- `deep`: Multiple index reconciliations and stale-entry pruning; require explicit confirmation.

## Steps
1. Validate required parameters.
2. Open ObsidianSkills/skill-list.md and preserve frontmatter fields and top-level sections.
3. Keep index entries under `## Vault Skills Index`.
4. For every skill folder, include both links: folder-level note file and local `SKILL.md`.
5. Add or update entries using this format:

```md
- Skill: [[path/to-note|Readable Title]]
  Description: One sentence explaining what it does and when to use it.
  Definition: [[path/to-skill/SKILL|Open SKILL.md]]
```

6. Remove stale entries when `remove_stale_entries` is true.
7. Keep descriptions non-overlapping.
8. Do not add or maintain a `Work Log` section in ObsidianSkills/skill-list.md.
9. Append a dated line to `ObsidianSkills/skills-changelog.md` for all skill-list changes.

## Output Contract
- Mode: `<fast|standard|deep>`
- Summary: 2-4 lines
- Changes Made: added/updated/removed entries and files touched
- Validation: pass or fail with top issues
- Next Actions: optional numbered list

## Stop Rules
1. Stop and ask if required parameters are missing.
2. Stop and ask if `change_type` conflicts with current file state.
3. Stop and ask before deep mode execution.

## Validation Checklist
- All required parameters were provided.
- Every link in ObsidianSkills/skill-list.md resolves to an existing file.
- Every skill entry has one `Description:` line and one `Definition:` line.
- Every `Definition:` line points to the corresponding local `SKILL.md` file.
- No duplicate entries for the same destination.
- ObsidianSkills/skill-list.md has no `Work Log` section.
- All skill-list changes are logged in `ObsidianSkills/skills-changelog.md`.

## Output Format
- Short summary of links added/updated/removed.
- Files touched list.

## Related
- [[ObsidianSkills/index-update/index-update|Index Update Skill Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
