# CLAUDE.md

Guidance for Claude Code (and other AI agents) working in this Obsidian vault.

## What this vault is

A personal **work-notes + skill-automation** Obsidian vault for an Allica Bank engineer.
It is folder-based, plain Markdown, and git-versioned. Workflows are codified as reusable
`SKILL.md` files rather than ad-hoc instructions.

## Skill-first rule (read before acting)

Before creating/updating notes or running any vault workflow, **check for a matching skill first**:

1. Open the canonical index: [`ObsidianSkills/skill-list.md`](ObsidianSkills/skill-list.md).
2. Read the matching `SKILL.md` **in full** before acting — do not guess at format or structure.
3. If no skill fits, follow [`ObsidianSkills/skill-format-guide/SKILL.md`](ObsidianSkills/skill-format-guide/SKILL.md) to create one.

This mirrors [`.github/copilot-instructions.md`](.github/copilot-instructions.md); `skill-list.md`
is the single source of truth. Keep the skill table below and `copilot-instructions.md` in sync with it.

## Structure map

| Path | Purpose |
|---|---|
| `My-Notes/` | Working notes & daily capture, organized by domain subfolder (`Azure/`, `Git/`, `Composer/`, `PET-AI/`, …). |
| `ObsidianSkills/` | Reusable workflow definitions; each skill = a folder with `SKILL.md` + a top-level note. |
| `ObsidianSkills/skill-list.md` | Canonical skills index. |
| `rules/` | Agent behaviour rules (e.g. `rules/github-rules/github-agent-rules.md`). |
| `githooks/` | Custom git hooks (`commit-msg`, `pre-commit`). |
| `logs/` | Automation logs (gitignored). |
| `hot.md` | Session-continuity cache — read first to resume context (see below). |
| `changelog.md` | Vault-level change log (non-skill changes). |
| `ObsidianSkills/skills-changelog.md` | Skill-specific change log. |
| `Oladapo.md` | Top-level redirect to `skill-list.md`. |

## Available skills

| Task | Skill Path |
|---|---|
| Create or update a daily/general note | `ObsidianSkills/daily-notes/SKILL.md` |
| Update the vault changelog | `ObsidianSkills/changelog-maintenance/SKILL.md` |
| Update the skill index | `ObsidianSkills/index-update/SKILL.md` |
| Create a new skill | `ObsidianSkills/skill-format-guide/SKILL.md` |
| Deduplicate notes or skills | `ObsidianSkills/deduplication-cron/SKILL.md` |
| Commit and push to GitHub | `ObsidianSkills/github-commit-push/SKILL.md` |
| Set up GitHub SSH | `ObsidianSkills/github-ssh-dapo-setup/SKILL.md` |
| Token/output optimization | `ObsidianSkills/token-optimization-standard/SKILL.md` |
| Locate Allica platform (PET) repos | `ObsidianSkills/allica-repo-locations/SKILL.md` |
| Log branch work (ticket, summary, PR) | `ObsidianSkills/work-log/SKILL.md` |

## Agent rules

Behaviour rules live under `rules/`. Read the matching rule before acting on that workflow.

| Workflow | Rule Path |
|---|---|
| Commit and push to GitHub | `rules/github-rules/github-agent-rules.md` |
| Create/update Jira tickets (PET) | `rules/jira-rules/jira-agent-rules.md` |
| Raise a CMW change request | `rules/jira-rules/cmw-change-request-rules.md` |
| Use MCP servers (Atlassian, PET-AI-Rules) | `rules/mcp-rules/mcp-agent-rules.md` |
| Terraform work in PET repos | `rules/terraform-rules/terraform-agent-rules.md` |

The Jira/CMW/MCP/Terraform rules are condensed mirrors of the canonical **PET-AI-Rules** repo,
which remains the source of truth. Full rules live at the local path
`/home/dapo/desktop/allica-repo/PET-AI-Rules` (`rules/jira/`, `rules/mcp/`, `rules/terraform/`,
`rules/templates/`) — agents should read the matching source file there for full detail.

## Frontmatter standard

Every note requires YAML frontmatter with these fields:

```yaml
---
title: Human Readable Title
tags:
  - lowercase-tag
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

- **Always refresh `updated`** when editing an existing note.
- Optional `status:` — `draft | active | evergreen`.
- Optional `type:` — `note | skill | index | runbook | review`.
- `SKILL.md` files use `name:` + `description:` instead of `title:` (see skill-format-guide).

## Conventions

- **Naming:** kebab-case for files and folders. Date-prefixed notes use `YYYY-MM-DD-<description>.md`.
- **Links:** wikilinks only — `[[path/to/note|Display Text]]`. No bare markdown links between notes.
- **Cross-links:** use a single `## Related` heading at the end of a note (do not introduce
  `## Links` or `## Cross-Links` — those are legacy and should be migrated to `## Related` when touched).
- **Atomic notes:** prefer one topic per note; split notes that grow to cover several things.

## Git

Follow [`rules/github-rules/github-agent-rules.md`](rules/github-rules/github-agent-rules.md) and the
`github-commit-push` skill. Commit messages use a single-word prefix enforced by the `commit-msg` hook: `SKILL`, `DOC`, `FIX`, `CHORE`, `FEAT`.
Only commit/push when the user asks. Log meaningful changes via the `changelog-maintenance` skill —
non-skill changes to `changelog.md`, skill changes to `ObsidianSkills/skills-changelog.md`.

## Session continuity

Read [`hot.md`](hot.md) first when resuming work — it holds a short, reverse-chronological "where we
left off" log. At the end of a substantial working session, prepend a brief entry (what changed,
decisions, next action). Keep it under ~500 words; it is a cache, not an archive — the durable
record is `changelog.md`.

## Guardrails (bank context)

- This vault belongs to an Allica Bank employee. **Do not** add real customer PII, account details,
  or material non-public information (MNPI) to notes — anonymise or redact first.
- **Do not delete** records, notes, or logs without explicit confirmation; data retention is subject
  to regulatory obligations. Prefer renaming/archiving over deletion.
- Flag anything that looks like it needs Compliance/Legal review rather than asserting a ruling.
