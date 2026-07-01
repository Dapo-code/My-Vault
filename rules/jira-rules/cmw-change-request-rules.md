---
title: CMW Change Request Agent Rules
tags:
  - jira
  - cmw
  - change-management
  - pet-ai
  - rules
created: 2026-07-01
updated: 2026-07-01
scope: repository
status: active
type: runbook
---

# Purpose

Condensed agent rules for raising **CMW (Change Management Workflow)** change requests for PET,
adapted from `PET-AI-Rules` → `rules/templates/cmw_change_request.md` and `cmw_risk_categorization.md`.
A CMW ticket is required (alongside a PET Jira ticket) for every production change.

> **Source of truth:** `PET-AI-Rules` repo, local path
> `/home/dapo/desktop/allica-repo/PET-AI-Rules` →
> `rules/templates/{cmw_change_request,cmw_risk_categorization}.md`.
> Load these before drafting a CRW — this file is a condensed mirror.

# Trigger

Apply whenever the agent is asked to create a CMW change request / CRW, or when a production change
needs change-management approval.

# Ticket Basics

- **Project:** `CMW` · **Issue type:** `Software Change Request` · **Component:** `PET` · **Engineering Area:** `PET`.
- **Summary format:** `[PET] - <concise change> - <ENV>` where ENV ∈ `PROD` / `STAGING` / `DEV` / `UAT`.
  One env per ticket — split multi-env changes into separate tickets.
- **Labels:** always `platform`; add `azure` and/or `gcp` by detecting cloud resource keywords in the change.
- **Assignee:** the raising PET engineer. The team roster (names + emails) is in the source
  `cmw_change_request.md` — reference it there rather than duplicating internal contact details in the vault.

# Description Structure (🔴 use full Jira/ADF markup, not plain prose)

Include, in order: a one/two-sentence plain-English summary, then:
`Environment`, `PET Ticket (PET-XXXXX)`, `PR / Pipeline` link, and sections
**What is changing** · **Why** · **Implementation Plan** · **Backout Plan** (with estimated backout time)
· **Testing / Verification** · **Risk Assessment** (the scored block below).

- Via MCP `editJiraIssue` → ADF (see [[rules/mcp-rules/mcp-agent-rules|MCP rules]] and source `rules/jira/mcp.md` for CMW field IDs).
- Via Jira UI → wiki markup. Via `acli --description` → the `--- Section ---` plain-text fallback.
- 🔴 **Never** pre-fill Implementation/Backout with generic placeholders — always derive from the actual change.

# Risk Categorisation (run before creating the ticket)

Score all **7 factors** 1–4, sum, and map to a level. Do **not** default everything to 1 — justify each;
when information is missing, score conservatively (higher) and note the uncertainty.

| Factor | 1 → 4 (low → high risk) |
|---|---|
| Blast Radius | single non-critical resource → customer-facing / shared core infra |
| Reversibility | instant rollback → no clean rollback (destructive/one-way) |
| Testing Coverage | fully tested in non-prod → no testing possible |
| Downtime Risk | zero-impact → extended/unpredictable downtime |
| Data Risk | no data touched → write/delete of customer data/PII/financial records |
| Security & Auth | none → network/firewall/Key Vault/identity change for prod |
| Dependency Risk | standalone → multiple teams / customer-critical path |

**Scoring:** `7–12 = Low`, `13–20 = Medium`, `21–28 = High`.

**Override to High** regardless of score if the change: touches prod network peering / NSG / firewall;
modifies an AKS cluster; deletes/disables a resource with active consumers; touches customer-facing auth
(Entra/OIDC/federation); has no rollback plan; or has never been tested anywhere.

## Risk Summary Block (paste into the CRW description)

```text
--- Risk Assessment ---
Blast Radius:      <1-4> — <justification>
Reversibility:     <1-4> — <justification>
Testing Coverage:  <1-4> — <justification>
Downtime Risk:     <1-4> — <justification>
Data Risk:         <1-4> — <justification>
Security Impact:   <1-4> — <justification>
Dependency Risk:   <1-4> — <justification>
                   ─────
Total Score:       <sum> / 28
Risk Level:        <Low | Medium | High>
Override Applied:  <Yes — reason | No>
```

# CMW Board Statuses (differ from the PET board)

`In Draft` → `For Peer Review` → `For Product Review` → `Awaiting implementation` → `Completed` (or `Cancelled`).

# AI Agent Workflow (🔴 confirmation required)

1. Read the referenced PET ticket + PR/diff to extract the change; detect environment and cloud labels.
2. Run the 7-factor risk scaffold, apply overrides, and present the scored Risk Summary Block to the user.
3. Draft Implementation Plan (approval → execute → verify → notify) and Backout Plan (numbered + est. time) from the real change.
4. **Ask the user to confirm** summary, description, risk block, and labels **before** creating — never create without explicit confirmation.
5. Create via `acli jira workitem create --project CMW --type "Software Change Request" --labels "platform[,azure][,gcp]" --component "PET"`.
6. After creation, remind the user to set in the Jira UI: **Change Start Date**, **Risk Level** (from the scored block), **Engineering Area** (`PET`) — these can't be set via `acli`.
7. Post the CMW ticket link as a comment on the originating PET ticket.

# Guardrails (bank context)

- The team roster, employee emails, and Change Start Date / Risk fields live in the source repo — reference, don't duplicate PII.
- Every production change needs **both** a PET ticket and this CMW ticket; no ticket = no change.

# Related

- [[rules/jira-rules/jira-agent-rules|Jira Ticket Creation Agent Rules]]
- [[rules/mcp-rules/mcp-agent-rules|MCP Connection Agent Rules]]
- [[rules/terraform-rules/terraform-agent-rules|Terraform Agent Rules]]
- [[My-Notes/PET-AI/pet-ai|PET-AI Note]]
