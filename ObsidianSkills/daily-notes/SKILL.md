---
name: daily-notes
description: Create or update daily notes with flexible titles and required metadata fields created and updated. Use when the user asks for daily planning, daily logs, or daily summaries.
---

# Daily Notes Skill

## Goal
Create consistent daily notes while allowing flexible titles.

## Rules
- Title and filename are flexible but must be descriptive.
- Frontmatter must include `created` and `updated`.
- `updated` must be refreshed whenever the note is edited.

## Template
```md
---
title: <Flexible Daily Title>
tags:
  - daily
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---

# <Flexible Daily Title>

## Top 3 Priorities
- 
- 
- 

## Schedule
- Morning:
- Afternoon:
- Evening:

## Work Log
- 

## Notes
- 

## Wins
- 

## Blockers
- 

## Carry Forward
- 

## Links
- [[Oladapo]]
```

## Steps
1. Create a new daily note with a descriptive title.
2. Insert the template.
3. Set `created` and `updated` to today's date.
4. Fill priorities first, then update the work log throughout the day.
5. Update `updated` on every edit.

## Validation Checklist
- Both `created` and `updated` exist.
- `updated` reflects last edit date.
- Note contains priorities and a work log section.

## Policy Reminder
- If this skill is indexed in Oladapo.md, the index must point to `daily-notes.md` and not `SKILL.md`.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
