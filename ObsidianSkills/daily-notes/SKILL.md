---
name: daily-notes
description: Create or update daily notes with flexible titles and required metadata fields created and updated. Use when the user asks for daily planning, daily logs, or daily summaries.
---

# Daily Notes Skill

## Goal
Create consistent daily notes while allowing flexible titles.

## Required Parameters
Collect these before running this skill:

1. note_date
- Date for the note in `YYYY-MM-DD`.

2. mode
- `create` or `update`.

3. note_path
- Target markdown file path for the daily note.

4. priorities
- Top 3 priorities to seed the note.

## Optional Parameters
1. note_title
- Human-readable title. Defaults to `Daily Note <note_date>` when omitted.

2. tags
- Additional tags to add alongside `daily`.

3. schedule_blocks
- Optional values for morning, afternoon, and evening.

## Parameter Rules
1. Do not create or update a note if `note_date`, `mode`, or `note_path` is missing.
2. Always set both `created` and `updated` on create.
3. Always refresh `updated` on update.
4. Keep `daily` tag present even when custom tags are provided.

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
1. Validate required parameters and derive defaults for optional parameters.
2. Create or open the note at `note_path` based on `mode`.
3. Insert or preserve the template and set `title` from `note_title`.
4. Set `created` and `updated` to `note_date` on create.
5. Fill priorities first, then update the work log throughout the day.
6. Refresh `updated` whenever the note is edited.

## Validation Checklist
- All required parameters were provided.
- Both `created` and `updated` exist.
- `updated` reflects last edit date.
- Note contains priorities and a work log section.

## Policy Reminder
- If this skill is indexed in Oladapo.md, the index must point to `daily-notes.md` and not `SKILL.md`.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
