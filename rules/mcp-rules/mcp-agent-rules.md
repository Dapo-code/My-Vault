---
title: MCP Connection Agent Rules
tags:
  - mcp
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

Condensed agent rules for connecting to and using the MCP servers referenced by `PET-AI-Rules`
(`rules/mcp/` and `rules/jira/mcp.md`). Captures connection, tool selection, and safety rules only.

> **Source of truth:** `PET-AI-Rules` repo, local path
> `/home/dapo/desktop/allica-repo/PET-AI-Rules` →
> `rules/mcp/{index,pet-server}.md` and `rules/jira/mcp.md`.

# Trigger

Apply whenever the agent uses an MCP server for Jira/Confluence, commit/branch validation,
rule lookup, or resource-to-source discovery.

# Servers and When to Use Them

| Server | Use for |
|---|---|
| **Atlassian MCP** (`com.atlassian/atlassian-mcp-server`) | Jira/Confluence operations needing **custom fields** or rich edits (Cloud Platform, CMW plans, labels on CMW). |
| **PET-AI-Rules MCP** (`pet-ai-rules`) | Commit/branch validation, staged-file checks, rule/skill discovery, resolving deployed resources back to source repos. |
| **Azure DevOps MCP** | Pipeline operations **only** — 🔴 never for tickets or boards. |

# Atlassian MCP

- HTTP transport at the Atlassian MCP URL; auth via the user's Atlassian session (no separate token).
- **Call `getAccessibleAtlassianResources` first** to get the `cloudId` — the Allica cloud ID and
  site (`eldonhouse…`) are recorded in the source `rules/jira/mcp.md`; do not hardcode them in the vault.
- Transition tools need a **numeric transition `id`** — call `getTransitionsForJiraIssue` first, never pass a status name.
- Key tools: `getJiraIssue`, `createJiraIssue`, `editJiraIssue` (custom fields), `addCommentToJiraIssue`,
  `searchJiraIssuesUsingJql`, `transitionJiraIssue`, `lookupJiraAccountId`.
- See [[rules/jira-rules/jira-agent-rules|Jira Agent Rules]] for the mandatory label/marker/field rules that apply to every MCP ticket write.

# PET-AI-Rules MCP Server

- Transport: HTTP `http://localhost:8001/mcp` (preferred); stdio fallback via the repo's `mcp-server/server.py`.
- 🔴 **Always `validate_commit_message` before finalising a commit message** (mirrors the `commit-msg` hook).
- 🔴 **Always `validate_branch_name` before creating/pushing a branch** (mirrors the `pre-push` hook).
- Also useful: `suggest_commit_message`, `suggest_branch_name`, `check_staged_files`,
  `get_rule` (URI form, e.g. `rules://terraform/naming`), `list_rules`, `search_content`,
  `get_convention`, `resolve_repo_from_tags` (deployed Azure/GCP resource → GitHub repo + module path).

# 🚨 Production Safety Guards (MANDATORY)

When MCP tools are used in the context of production infrastructure:

1. **Never modify production directly.** Agents cannot apply Terraform or run modification commands against the production subscription (ID held in `PET-AI-Rules` `rules/docs/security.md` §8).
2. **Ticket + CMW required** for all production changes — a PET Jira ticket **and** a CMW change ticket.
3. **No ticket = no work** — offer to create one instead.
4. **IaC first** — production changes go through Terraform where possible.
5. **Branch linking** — all branches link to a Jira ticket: `type/description/PET-12345`.

Production is identified by patterns like `*-prod-*`, `*-prd-*`, `ABL-Prod-*`, and prod tags/RG names —
recognise these and apply the guards. Full identifiers and the emergency exception process live in the source repo.

# Guardrails (bank context)

- Do not hardcode the production subscription ID, Atlassian cloud ID, or site name in the vault —
  reference the source repo where they are recorded.
- Treat any customer data surfaced through MCP tools as confidential; do not persist it into notes.

# Related

- [[rules/jira-rules/jira-agent-rules|Jira Ticket Creation Agent Rules]]
- [[rules/terraform-rules/terraform-agent-rules|Terraform Agent Rules]]
- [[My-Notes/PET-AI/pet-ai|PET-AI Note]]
