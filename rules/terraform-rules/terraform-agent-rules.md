---
title: Terraform Agent Rules
tags:
  - terraform
  - pet-ai
  - rules
  - infrastructure
created: 2026-07-01
updated: 2026-07-01
scope: repository
status: active
type: runbook
---

# Purpose

Condensed agent rules for Terraform work in Allica PET repos, adapted from the canonical
`PET-AI-Rules` repo (`rules/terraform/`, 20+ topic files). Captures the core rules and a task map;
load the specific source file before doing the detailed work.

> **Source of truth:** `PET-AI-Rules` repo, local path
> `/home/dapo/desktop/allica-repo/PET-AI-Rules` → `rules/terraform/*.md`.
> This is a condensed index, not a replacement.

# Trigger

Apply whenever the agent writes, reviews, refactors, or plans Terraform for PET infrastructure.

# Core Rules

1. Prefer **direct references, module outputs, or `_config`** over data sources wherever possible.
2. Keep file layout **explicit and predictable** (see source `files.md`, `modules.md`).
3. Use **`moved` blocks or controlled state moves** for renames — never rely on destroy-and-recreate.
4. **Plan output must match intent**, and re-planning after apply should show **no drift**.
5. Use **PET shared modules**; read the module's `.module-meta` and `spec.md` before pinning or calling it.
6. Follow PET **naming** and **tagging** conventions — tags also drive resource→source discovery
   (`resolve_repo_from_tags` via the PET-AI-Rules MCP).

# Task Map (load the matching source file)

| Task | Source file(s) under `rules/terraform/` |
|---|---|
| New workspace (end-to-end) | `workspace-template`, `workspace-conventions`, `files`, `naming` (+ `../docs/devops`) |
| New resources / modules | `resources`, `naming`, `files`, `variables`, `outputs` |
| PET module provisioning | `config-module`, `pet-terraform-modules`, `pet-terraform-module-index`, `workspace-conventions` |
| Shared module discovery | `pet-terraform-module-index`, `pet-terraform-modules`, `config-module` |
| VNets, spokes, routing | `pet-terraform-modules` (+ `../network/networking`) |
| Refactors and renames | `moves`, `state` |
| Data lookups / shared config | `data`, `config-module` |
| Security and access | `rbac`, `identity`, `privateendpoints` (+ `../docs/security`) |
| Provider upgrades | `providers`, `moves` |
| Locals / computed values | `locals` |
| Resource tagging | `tagging` |

# Production Safety

Terraform changes to production must follow the MCP production guards: **no direct apply to production**,
**ticket + CMW required**, **IaC first**, **branch linked to a Jira ticket**. See
[[rules/mcp-rules/mcp-agent-rules|MCP Connection Agent Rules]] for the full guard list.

# Guardrails (bank context)

- Never commit Terraform state (`*.tfstate`) or secrets — the PET-AI-Rules `check_staged_files` MCP tool
  and gitignore rules block these; respect them.
- Production subscription IDs and other infra identifiers are held in the source repo — do not duplicate them here.

# Related

- [[rules/mcp-rules/mcp-agent-rules|MCP Connection Agent Rules]]
- [[rules/jira-rules/jira-agent-rules|Jira Ticket Creation Agent Rules]]
- [[My-Notes/PET-AI/pet-ai|PET-AI Note]]
