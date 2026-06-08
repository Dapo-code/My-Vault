---
name: skill-format-guide
description: Create new vault skills using the standard folder-based SKILL.md format with a paired top-level note file and proper Oladapo.md indexing rules.
---

# Skill Format Guide Skill

## Goal
Create skills consistently across the vault using a standard structure and indexing policy.

This is the canonical guide for creating new skills going forward.

## Required Structure
For each new skill, create a folder under ObsidianSkills:

- ObsidianSkills/<skill-name>/SKILL.md
- ObsidianSkills/<skill-name>/<skill-name>.md

## Naming Rules
- Folder name: lowercase with hyphens.
- Frontmatter name field in SKILL.md: same as folder name.
- Top-level note filename: same as folder name.

## SKILL.md Format
1. Add YAML frontmatter with at least:
   - name
   - description
2. Add a short title header and clear step-by-step instructions.
3. Include validation checks.
4. Include related links where helpful.

## Top-Level Skill Note Format
The <skill-name>.md note should include:
1. A simple one-paragraph description.
2. A link to the local SKILL.md file.
3. Optional related links.

## Reference Guidance
When creating a new skill, follow this guide before writing the folder note or the SKILL.md file.

## Oladapo Index Policy
1. Add links in Oladapo.md only to top-level skill note files.
2. Never link Oladapo.md directly to any SKILL.md file.
3. Keep one-line descriptions under each skill link.

## Creation Workflow
1. Create skill folder and both files.
2. Write SKILL.md instructions.
3. Write the simple top-level skill note.
4. Add only the top-level note link to Oladapo.md.
5. Add a dated entry to ObsidianSkills/skills-changelog.md.

## Validation Checklist
- Skill folder contains both SKILL.md and <skill-name>.md.
- SKILL.md has valid frontmatter and clear instructions.
- Oladapo.md links to <skill-name>.md only.
- No Oladapo.md links point to SKILL.md files.
- ObsidianSkills/skills-changelog.md contains an entry for the addition.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
