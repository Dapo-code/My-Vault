---
applyTo: "**"
---
# Work Log Instructions

Oladapo keeps a personal vault at `/mnt/c/my-vault` with a branch work-log system.
Every branch in this repo has a note at:

```
/mnt/c/my-vault/My-Notes/Work-Log/<REPO>/<BRANCH>.md
```

Resolve `<REPO>` and `<BRANCH>` at runtime:
```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

## When to apply

Trigger this workflow when the user says anything like:
- "log my work", "update work log", "record what I did"
- "add to my work log: <description>"
- "set PR link", "close my work log", "mark ticket done"

## Actions

### Log work done
Append a dated bullet under `## Work Summary` in the note:
`- **YYYY-MM-DD**: <description>`
Refresh `updated` in frontmatter to today's date.

### Set ticket details
Fill in `- **Jira Ticket:**` and `- **Ticket Title:**` under `## Branch Info`.
Refresh `updated`.

### Set PR link
Fill in `- **PR Link:**` under `## Branch Info`.
Refresh `updated`.

### Close the log
Set `status: done` in frontmatter.
Confirm `- **PR Link:**` is populated.
Refresh `updated`.

## If the note doesn't exist yet
Create it with:
```bash
bash /mnt/c/my-vault/ObsidianSkills/work-log/scripts/create_branch_note.sh "$REPO" "$BRANCH"
```
Then fill in details as requested.

## Note
This file is local-only and not committed to this repo.
Full skill definition: `/mnt/c/my-vault/ObsidianSkills/work-log/SKILL.md`
