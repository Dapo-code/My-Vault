---
name: work-log
description: Create, update, or close a branch work-log note in My-Notes/Work-Log/<repo>/<branch>.md — capturing Jira ticket, work summary, and PR link for a feature branch in an Allica repo.
---

# Work Log Skill

## Goal
Maintain a per-branch work-log note for every Allica platform repo branch so work, ticket
references, and PR links are recorded in the vault. Stub notes are auto-created by the
`post-checkout` git hook; this skill fills in and maintains the content.

## Required Parameters

1. `repo_name`
   - The PET repo name, e.g. `PET-dns`. Must match the folder name under `/home/dapo/desktop/allica-repo`.

2. `branch_name`
   - Full branch name including any prefix, e.g. `feat/PET-123-add-dns-rule`.

3. `mode`
   - `create` — fill in ticket details on a stub note (hook already created the file).
   - `update` — append to Work Summary or Key Changes; refresh `updated`.
   - `close` — set `status: done`, confirm PR link is set, refresh `updated`.

## Optional Parameters

1. `ticket_id`
   - Jira ticket ID, e.g. `PET-123`. Required for `create` mode.

2. `ticket_title`
   - Human-readable title from Jira, e.g. *"Add private DNS rule for storage account"*.

3. `pr_link`
   - Full URL to the pull request. Provide when raising or merging a PR.

4. `work_summary`
   - Free-text update to append to the Work Summary section.

## Parameter Rules

1. Note path is always `My-Notes/Work-Log/<repo_name>/<branch_name>.md`.
   - Branch names with `/` (e.g. `feat/PET-123`) become sub-paths — `mkdir -p` handles this.
2. On `create`: if the file already exists as a stub (hook-created), fill in ticket fields only.
   Do not overwrite existing Work Summary content.
3. On `update`: append `work_summary` as a bullet under `## Work Summary`. Always refresh `updated`.
4. On `close`: set `status: done` in frontmatter, ensure `## PR Link` is populated, refresh `updated`.
5. Protected branches (`main`, `master`, `develop`, `development`) are never logged.
6. Always refresh `updated` on every write.

## Mode Selector

- `fast`: mode=update with clear `work_summary` text, note already exists.
- `standard`: mode=create filling in ticket details, or mode=close.
- `deep`: bulk update across multiple branches or repos — require explicit scope confirmation.

## Steps

### create
1. Resolve note path: `My-Notes/Work-Log/<repo_name>/<branch_name>.md`.
2. If file does not exist, create it using the template below.
3. Fill in `ticket_id`, `ticket_title`, and `pr_link` (if provided) in `## Branch Info`.
4. Refresh `updated` in frontmatter.

### update
1. Resolve note path and confirm it exists.
2. Append `work_summary` as a dated bullet under `## Work Summary`:
   `- **YYYY-MM-DD**: <work_summary text>`
3. Refresh `updated` in frontmatter.

### close
1. Resolve note path and confirm it exists.
2. Set `status: done` in frontmatter.
3. Set `pr_link` in `## Branch Info` if not already set.
4. Refresh `updated` in frontmatter.

## Note Template

```md
---
title: <branch_name>
tags:
  - work-log
  - <repo_name>
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
status: in-progress
---

# <branch_name>

## Branch Info
- **Repo:** <repo_name>
- **Branch:** <branch_name>
- **Jira Ticket:** <ticket_id>
- **Ticket Title:** <ticket_title>
- **PR Link:** <pr_link>

## Work Summary


## Key Changes


## Notes / Learnings
```

## Output Contract

```
Mode: <create|update|close>
Note: My-Notes/Work-Log/<repo_name>/<branch_name>.md
Action: <what was written or updated>
```

## Validation Checklist

- [ ] Note path starts with `My-Notes/Work-Log/`
- [ ] `updated` field is refreshed
- [ ] `status` is `in-progress` (create/update) or `done` (close)
- [ ] Ticket ID follows `PET-NNN` format
- [ ] PR link is a full URL when provided

## Related
- [[ObsidianSkills/work-log/work-log|Work Log Skill Note]]
- [[My-Notes/Work-Log/index|Work Log Index]]
- [[ObsidianSkills/allica-repo-locations/allica-repo-locations|Allica Repo Locations]]
- [[rules/jira-rules/jira-agent-rules|Jira Agent Rules]]
