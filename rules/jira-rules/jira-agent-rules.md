---
title: Jira Ticket Creation Agent Rules
tags:
  - jira
  - pet-ai
  - rules
  - workflow
created: 2026-07-01
updated: 2026-07-01
scope: repository
status: active
type: runbook
---

# Purpose

Condensed agent rules for creating and updating Jira tickets in the Allica **PET** project,
adapted from the canonical `PET-AI-Rules` repo (`rules/jira/`). This file captures the mandatory
rules only — load the source repo for full `acli`/MCP command detail.

> **Source of truth:** `PET-AI-Rules` repo, local path
> `/home/dapo/desktop/allica-repo/PET-AI-Rules` →
> `rules/jira/{index,lifecycle,acli,mcp,comments,linking}.md`.
> This is a condensed mirror; when the two disagree, the source repo wins.

# Trigger

Apply whenever the agent is asked to create, update, comment on, transition, or link a Jira ticket.

# Mandatory Rules (🔴 MUST)

1. **AI markers on every AI-touched ticket:**
   - Add the Jira label `helped-pet-ai`. Labels **replace**, not append — read existing labels first,
     add `helped-pet-ai`, deduplicate, then write the full list.
   - Include the literal text `helped by pet-ai rules` in the description or comment body (text marker, not a label — it has spaces).
2. **Purpose statement first.** Every description opens with a one-/two-sentence **Purpose**: the problem/goal + the expected outcome (definition of done).
3. **Details specification on create** — include a section with:
   - `Target Date (YYYY-MM-DD)` — default end of current month, but confirm with the user first.
   - `Due Date (YYYY-MM-DD)`.
   - `Estimate (T-shirt size)` — one of `S` / `M` / `L` / `XL`.
   - `Cloud Platform` — one of `Azure` / `GCP` / `AWS` / `Other` / `None` (default `Azure` unless context says otherwise).
   - `Components` — one of `Database` / `Networks` / `DevOps` / `Windows` / `Platform` (default `Platform`).
4. **Dates:** scripted/API inputs must be `YYYY-MM-DD` (regex `^\d{4}-\d{2}-\d{2}$`), even though the Jira UI may display `DD/MM/YYYY`.
5. **Default project `PET`**; **assignee = ticket creator** at creation unless told otherwise; **priority** default Medium (assess, don't blindly default).
6. **Git references:** use the remote origin URL or `org/repo` short form — **never** local machine paths.

# AI-Optimised Body Structure

Structure bodies so an agent can consume any section independently: bold `**Section**` headings, bullet
lists, fenced code blocks for commands/paths, self-contained sections (no "as mentioned above").
Recommended sections: **Purpose** (required), **Background**, **Scope**, **Acceptance Criteria**,
**Implementation Notes**, **Risks**.

# PET Board Statuses (only these are valid)

`Backlog`, `Prioritised`, `Refined`, `In Progress`, `Pull Request`, `Testing`, `Done`, `Blocked`,
`Blocked - 3rd Party`, `Rejected`, `Closed`.

❌ Do **not** use: `To Do`, `In Review`, `Ready to Deploy`, `Ready to Merge`, `Code Review`, `Deployed`.

## Transition matrix (no skipping — Jira rejects skipped steps)

| From | Allowed to |
|---|---|
| `Backlog` | `Prioritised`, `Refined`, `Blocked` |
| `Prioritised` | `Backlog`, `Refined`, `In Progress`, `Blocked` |
| `Refined` | `Backlog`, `Prioritised`, `Blocked` |
| `In Progress` | `Pull Request`, `Testing`, `Blocked` |
| `Pull Request` | `Testing`, `In Progress`, `Blocked` |
| `Testing` | `Done`, `In Progress` |
| `Blocked` | `Prioritised`, `In Progress` |

Happy path: `Backlog → Prioritised → In Progress → Pull Request → Testing → Done`.

# Tooling: MCP vs acli (summary)

- **MCP-enabled session** (e.g. VS Code Copilot Chat) → prefer Atlassian MCP tools, especially for
  **custom fields** (Cloud Platform, Target Date, T-shirt), CMW structured fields, and CMW labels.
- **Terminal / scripts / CI** → use `acli`. Read the source `acli.md` **in full** before any CLI op.
- **Never** use the Azure DevOps MCP for tickets/boards — Jira/Confluence only via Atlassian MCP or `acli`.
- `acli` gotchas: run `acli jira auth status` first; syntax is `acli <product> <entity> <action>`;
  `view` takes a positional key (not `--key`); use `--labels` (plural), `--body-file` (ADF JSON, not `--body`);
  always `--yes` on transitions. Cloud Platform cannot be set via CLI on Task/Story/Bug — use MCP.

# Linking

Use real Jira links (`acli jira workitem link create`), not comments mentioning another ticket.
`depends on` → `Dependent` (ordering); `Blocks` = hard blocker only. If a relationship maps to more
than one link type, ask rather than guess. Full link-type table in the source `acli.md`.

# Guardrails (bank context)

- Custom field IDs and the Allica Atlassian cloud ID / site are held in the source repo
  (`rules/jira/mcp.md`) — reference them there rather than duplicating infra identifiers here.
- Do not put real customer PII or MNPI in ticket bodies; anonymise first.

# Related

- [[rules/jira-rules/cmw-change-request-rules|CMW Change Request Agent Rules]]
- [[rules/mcp-rules/mcp-agent-rules|MCP Connection Agent Rules]]
- [[rules/github-rules/github-agent-rules|GitHub Agent Commit and Push Rules]]
- [[My-Notes/PET-AI/pet-ai|PET-AI Note]]
