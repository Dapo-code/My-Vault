---
name: deduplication-cron
description: Detect and merge duplicate notes/skills on a schedule. Use when setting up or maintaining deduplication automation and link-safe merges.
disable-model-invocation: true
---

# Deduplication Cron Skill

## Goal
Prevent duplicate notes and duplicate skills, then merge duplicates into one canonical file.

## Script
- ObsidianSkills/deduplication-cron/scripts/deduplicate_notes_and_skills.sh

## Behavior
1. Find duplicate markdown files by normalized key.
2. Handle `SKILL.md` specially by keying on parent folder name.
3. Choose a canonical file for each duplicate group.
4. Merge duplicate content into canonical file.
5. Rewrite Obsidian wiki links to canonical target.
6. Remove merged duplicates.

## Manual Commands
```bash
# Dry run
bash /mnt/c/my-vault/ObsidianSkills/deduplication-cron/scripts/deduplicate_notes_and_skills.sh --vault /mnt/c/my-vault

# Apply merge
bash /mnt/c/my-vault/ObsidianSkills/deduplication-cron/scripts/deduplicate_notes_and_skills.sh --apply --vault /mnt/c/my-vault
```

## Cron Setup
```bash
line='30 2 * * * /bin/bash /mnt/c/my-vault/ObsidianSkills/deduplication-cron/scripts/deduplicate_notes_and_skills.sh --apply --vault /mnt/c/my-vault >> /mnt/c/my-vault/logs/dedupe.log 2>&1'
(crontab -l 2>/dev/null | grep -Fv '/mnt/c/my-vault/ObsidianSkills/deduplication-cron/scripts/deduplicate_notes_and_skills.sh'; echo "$line") | crontab -
```

## Safety Rules
- Run dry run before enabling a new schedule.
- Verify link rewrites after merge.
- Log merge actions in changelog.md.
- If this skill is indexed in Oladapo.md, link `deduplication-cron.md` and never link `SKILL.md` directly.

## Verification
```bash
crontab -l
tail -n 50 /mnt/c/my-vault/logs/dedupe.log
```

## Related
- [[Oladapo]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
