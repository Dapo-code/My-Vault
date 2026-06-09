---
name: deduplication-cron
description: Detect and merge duplicate notes/skills on a schedule. Use when setting up or maintaining deduplication automation and link-safe merges.
disable-model-invocation: true
---

# Deduplication Cron Skill

## Goal
Prevent duplicate notes and duplicate skills, then merge duplicates into one canonical file.

## Required Parameters
Collect these before running this skill:

1. vault_path
- Absolute path to the vault root (for example `/mnt/c/my-vault`).

2. run_mode
- `dry-run` or `apply`.

3. script_path
- Path to `deduplicate_notes_and_skills.sh`.

## Optional Parameters
1. cron_schedule
- Cron expression for automation. Defaults to `30 2 * * *`.

2. log_path
- Log destination. Defaults to `/mnt/c/my-vault/logs/dedupe.log`.

3. include_changelog_update
- Boolean for whether to log merge activity in changelog after apply.

## Parameter Rules
1. Always run `dry-run` first before first-time or changed schedules.
2. Do not run `apply` if `vault_path` or `script_path` is missing.
3. Preserve link safety by validating rewritten wiki links after merges.
4. If indexed in ObsidianSkills/skill-list.md, include both `deduplication-cron.md` and `SKILL.md` links using `Skill:` and `Definition:` lines.

## Mode Selector
- `fast`: Run dry-run only and report findings.
- `standard`: Dry-run plus apply after explicit approval.
- `deep`: Apply plus cron schedule updates and post-merge troubleshooting; require explicit confirmation.

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
- If this skill is indexed in ObsidianSkills/skill-list.md, include both the `Skill:` link to `deduplication-cron.md` and the `Definition:` link to `SKILL.md`.

## Steps
1. Validate required parameters.
2. Run `dry-run` using `vault_path` and `script_path`.
3. Review proposed canonical targets and link rewrites.
4. Run `apply` only when approved.
5. Configure cron with `cron_schedule` and `log_path` if automation is requested.
6. Update changelog when `include_changelog_update` is true.

## Output Contract
- Mode: `<fast|standard|deep>`
- Summary: 2-4 lines
- Changes Made: dry-run/apply results, cron updates, files affected
- Validation: pass or fail with top issues
- Next Actions: optional numbered list

## Stop Rules
1. Stop and ask if required parameters are missing.
2. Stop before `apply` when dry-run has not completed.
3. Stop and ask before deep mode execution.

## Verification
```bash
crontab -l
tail -n 50 /mnt/c/my-vault/logs/dedupe.log
```

## Validation Checklist
- All required parameters were provided.
- Dry run completed before apply.
- Post-merge links resolve to canonical targets.
- Cron entry points to the expected script and vault path.

## Related
- [[ObsidianSkills/deduplication-cron/deduplication-cron|Deduplication Cron Skill Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
