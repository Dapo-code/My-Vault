---
name: index-update
description: Maintain Oladapo.md as the top-level vault index. Use when adding, moving, removing, or renaming notes/skills that should be discoverable from the root index.
---

# Index Update Skill

## Goal
Keep Oladapo.md clear, current, and scannable.

## Inputs
- A changed or newly created note/skill path.
- A one-sentence purpose for that note/skill.

## Steps
1. Open Oladapo.md.
2. Keep the opening sentence intact.
3. Keep index entries under `## Vault Skills Index`.
4. Never add direct links to any `SKILL.md` file in Oladapo.md.
5. For every skill folder, link the folder-level note file (for example `deduplication-cron.md`) instead of `SKILL.md`.
6. For skill-related additions or edits, append a dated entry to `ObsidianSkills/skills-changelog.md` instead of the top-level `changelog.md`.
7. Add or update entries using this format:

```md
- [[path/to-note|Readable Title]]
  Description: One sentence explaining what it does and when to use it.
```

8. Remove stale entries that point to moved/deleted files.
9. Keep descriptions non-overlapping.
10. Append a dated line to changelog.md after each non-skill index update.

## Validation Checklist
- Every link in Oladapo.md resolves to an existing file.
- Every link has one `Description:` line beneath it.
- No Oladapo.md entry points to a `SKILL.md` file.
- No duplicate entries for the same destination.
- changelog.md has an entry for non-skill index edits.
- ObsidianSkills/skills-changelog.md has an entry for skill-related edits.

## Output Format
- Short summary of links added/updated/removed.
- Files touched list.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
