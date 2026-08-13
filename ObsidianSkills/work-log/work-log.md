---
title: Work Log Skill
tags:
  - work-log
  - skill
  - allica
  - pet
created: 2026-08-13
updated: 2026-08-13
status: active
type: skill
---

# Work Log Skill

Tracks work done on feature branches across the 19 Allica platform repos in `/home/dapo/desktop/allica-repo`.

A `post-checkout` git hook installed in every repo automatically creates a stub note in
`My-Notes/Work-Log/<repo>/<branch>.md` the moment you create or switch to a branch.
The Copilot agent then fills in the Jira ticket, work summary, and PR link via this skill.

## How It Works

```
git checkout -b feat/PET-123-add-dns-rule
       ↓
post-checkout hook fires
       ↓
create_branch_note.sh creates:
  My-Notes/Work-Log/PET-dns/feat/PET-123-add-dns-rule.md  (stub)
       ↓
Ask Copilot to fill in ticket details, work done, PR link
```

## Hook Management

| Action | Command |
|---|---|
| One-time install (all repos) | `bash ObsidianSkills/work-log/scripts/install_hooks.sh --apply` |
| Dry-run (preview) | `bash ObsidianSkills/work-log/scripts/install_hooks.sh` |
| Auto-sync new repos | cron Mondays 10:00 → `sync_hooks.sh` |
| Manual sync | `bash ObsidianSkills/work-log/scripts/sync_hooks.sh` |
| Sync log | `logs/work-log-hook-sync.log` |

## Protected Branches

The hook silently skips: `main`, `master`, `develop`, `development`.

## Agent Commands

- **Start a log**: *"create a work log for PET-dns / feat/PET-123, ticket PET-123 — Add DNS rule"*
- **Update work done**: *"add to my work log for PET-123: updated Terraform module and applied"*
- **Record PR**: *"set PR link for PET-dns / feat/PET-123 to https://github.com/…/pull/42"*
- **Close a log**: *"close the work log for PET-dns / feat/PET-123"*

## Related
- [[ObsidianSkills/work-log/SKILL|Open SKILL.md]]
- [[My-Notes/Work-Log/index|Work Log Index]]
- [[ObsidianSkills/allica-repo-locations/allica-repo-locations|Allica Repo Locations]]
- [[rules/jira-rules/jira-agent-rules|Jira Agent Rules]]
