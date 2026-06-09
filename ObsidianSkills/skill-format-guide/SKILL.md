---
name: skill-format-guide
description: Create new vault skills using a parameter-driven standard folder structure, paired top-level note, and proper ObsidianSkills/skill-list.md indexing rules.
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

6. mode_selector
- Must define `fast`, `standard`, and `deep` execution modes.

7. output_contract
- Fixed concise response skeleton for predictable token usage.

## Optional Parameters
1. related_links
- Relevant vault links to include under Related.

2. top_level_note_summary
- One paragraph for the paired skill note file.

3. index_description
- One-line description shown in ObsidianSkills/skill-list.md.

4. changelog_entry
- Dated line for ObsidianSkills/skills-changelog.md.

5. deep_mode_triggers
- Conditions that are allowed to activate `deep` mode.

## Parameter Rules
1. Do not create a skill if any required parameter is missing.
2. If required parameters are missing, ask follow-up questions first.
3. Normalize skill_name to lowercase with hyphens.
4. Frontmatter name must match skill_name exactly.
5. Use defaults only for optional parameters when not provided.
6. In `SKILL.md`, the Related section must include the folder-level `<skill-name>.md` link and must not include `ObsidianSkills/skill-list.md`.
7. Every new skill must default to `fast` mode unless a trigger requires `standard` or `deep`.
8. Validation checklist must be capped at 3-5 concrete checks.

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
- Mode Selector (from mode_selector)
- Output Contract (from output_contract)
- Validation Checklist (from validation_checklist)
- Related (include folder-level `<skill-name>.md` link; optional extra links from related_links)

3. Keep section content concise:
- Goal: 1-2 lines.
- Each step: one short imperative line.
- No long examples unless user requests examples.

## Top-Level Skill Note Format
The <skill-name>.md note should include:
1. A simple one-paragraph description (from top_level_note_summary or generated from goal + description).
2. A link to the local SKILL.md file.
3. Optional related links.

## Skill Index Policy
1. Add links in ObsidianSkills/skill-list.md only to top-level skill note files.
2. Add a paired `Definition:` link in each entry that points to the skill's local `SKILL.md` file.
3. Keep one-line descriptions under each skill link (from index_description if provided).
4. Do not add a `Work Log` section to ObsidianSkills/skill-list.md.
5. Route all skill-list changes to `ObsidianSkills/skills-changelog.md`.
6. Use this exact entry format when adding a skill to ObsidianSkills/skill-list.md:

```md
- Skill: [[ObsidianSkills/<skill-name>/<skill-name>|Readable Skill Title]]
	Description: One sentence explaining what it does and when to use it.
	Definition: [[ObsidianSkills/<skill-name>/SKILL|Open SKILL.md]]
```

## Creation Workflow
1. Gather and validate required parameters.
2. Create skill folder and both files.
3. Write SKILL.md from parameters and enforce token budget rules.
4. Write top-level skill note from parameters.
5. Add `Skill:` and `Definition:` links to ObsidianSkills/skill-list.md.
6. Add a dated entry to ObsidianSkills/skills-changelog.md.

## Validation Checklist
- All required parameters were provided before file creation.
- Skill folder contains both SKILL.md and <skill-name>.md.
- SKILL.md frontmatter name matches folder name.
- SKILL.md contains Goal, Steps, Mode Selector, Output Contract, and Validation Checklist derived from parameters.
- SKILL.md Related includes the local `<skill-name>.md` link.
- SKILL.md Related does not link to ObsidianSkills/skill-list.md.
- ObsidianSkills/skill-list.md `Skill:` line links to <skill-name>.md.
- ObsidianSkills/skill-list.md also includes a `Definition:` link to the local SKILL.md.
- ObsidianSkills/skill-list.md does not contain a `Work Log` section.
- SKILL.md defaults to `fast` mode and defines deep mode trigger conditions.
- Validation checklist has 3-5 checks.
- ObsidianSkills/skills-changelog.md contains an entry for the addition.

## Related
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
- [[ObsidianSkills/token-optimization-standard/token-optimization-standard|Token Optimization Standard Note]]
