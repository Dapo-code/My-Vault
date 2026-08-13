---
title: Work Log Index
tags:
  - work-log
  - index
created: 2026-08-13
updated: 2026-08-13
---

# Work Log Index

Active and historical branch work logs for Allica platform repos.

Notes are auto-created by `post-checkout` git hooks installed across all repos under
`/home/dapo/desktop/allica-repo`. One note per branch, organised by repo.

## How to Use

1. **Start work on a branch** — check out the branch; the hook creates
   `My-Notes/Work-Log/<repo>/<branch>.md` automatically.
2. **Add ticket details** — ask Copilot: *"update my work log for PET-dns /
   feat/PET-123-add-dns-rule with ticket PET-123"*.
3. **Log work done** — ask Copilot: *"add to my work summary for branch PET-123"*.
4. **Raise PR** — ask Copilot to record the PR link.
5. **Close the log** — ask Copilot: *"close the work log for PET-123"* when the branch is merged.

## Hook Management

- One-time install: `bash ObsidianSkills/work-log/scripts/install_hooks.sh --apply`
- Auto-sync (new repos): runs every Monday at 10:00 via cron → logs to `logs/work-log-hook-sync.log`
- Manual sync: `bash ObsidianSkills/work-log/scripts/sync_hooks.sh`

## Branch Logs

<!-- Branch log notes appear here under per-repo subfolders as you work -->

## Related
- [[ObsidianSkills/work-log/work-log|Work Log Skill]]
- [[ObsidianSkills/allica-repo-locations/allica-repo-locations|Allica Repo Locations]]
