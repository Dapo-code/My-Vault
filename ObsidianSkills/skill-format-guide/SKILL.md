---
name: skill-format-guide
description: Create new vault skills using a parameter-driven standard folder structure, paired top-level note, and proper Oladapo indexing rules.
---

# Skill Format Guide Skill

## Goal
Create skills consistently across the vault using required parameters, standard structure, and indexing policy.

This is the canonical guide for creating new skills going forward.

## Required Parameters
Collect these before creating any new skill files:

1. skill_name
- Lowercase, hyphenated identifier (example: note-quality-check)

2. description
- One sentence describing when the skill should be used.

3. goal
- Clear outcome statement for the skill.

4. steps
- Ordered workflow steps the skill must follow.

5. validation_checklist
- Concrete checks that confirm correct execution.

## Optional Parameters
1. related_links
- Relevant vault links to include under Related.

2. top_level_note_summary
- One paragraph for the paired skill note file.

3. index_description
- One-line description shown in Oladapo index.

4. changelog_entry
- Dated line for ObsidianSkills/skills-changelog.md.

## Parameter Rules
1. Do not create a skill if any required parameter is missing.
2. If required parameters are missing, ask follow-up questions first.
3. Normalize skill_name to lowercase with hyphens.
4. Frontmatter name must match skill_name exactly.
5. Use defaults only for optional parameters when not provided.

## Required Structure
For each new skill, create a folder under ObsidianSkills:

- ObsidianSkills/<skill-name>/SKILL.md
- ObsidianSkills/<skill-name>/<skill-name>.md

## Naming Rules
- Folder name: same as skill_name.
- Frontmatter name field in SKILL.md: same as skill_name.
- Top-level note filename: same as skill_name.

## SKILL.md Format
1. Add YAML frontmatter with:
- name = skill_name
- description = description

2. Add sections in this order:
- Goal (from goal)
- Steps (from steps)
- Validation Checklist (from validation_checklist)
- Related (optional, from related_links)

## Top-Level Skill Note Format
The <skill-name>.md note should include:
1. A simple one-paragraph description (from top_level_note_summary or generated from goal + description).
2. A link to the local SKILL.md file.
3. Optional related links.

## Oladapo Index Policy
1. Add links in Oladapo.md only to top-level skill note files.
2. Never link Oladapo.md directly to any SKILL.md file.
3. Keep one-line descriptions under each skill link (from index_description if provided).

## Creation Workflow
1. Gather and validate required parameters.
2. Create skill folder and both files.
3. Write SKILL.md from parameters.
4. Write top-level skill note from parameters.
5. Add only top-level note link to Oladapo.md.
6. Add a dated entry to ObsidianSkills/skills-changelog.md.

## Validation Checklist
- All required parameters were provided before file creation.
- Skill folder contains both SKILL.md and <skill-name>.md.
- SKILL.md frontmatter name matches folder name.
- SKILL.md contains Goal, Steps, and Validation Checklist derived from parameters.
- Oladapo.md links to <skill-name>.md only.
- No Oladapo.md links point to SKILL.md files.
- ObsidianSkills/skills-changelog.md contains an entry for the addition.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
