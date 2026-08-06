---
name: allica-repo-locations
description: Tells the agent where Oladapo's Allica platform (PET) repositories are checked out locally so it can find, read, or clone them without searching the filesystem.
---

# Allica Repo Locations Skill

## Goal
Give the agent an authoritative, single place to find all local Allica platform-engineering (PET) repositories.

## Repo Root
All Allica platform-job repos are cloned under:

`/home/dapo/desktop/allica-repo`

This directory is the source of truth. Run `ls -1 /home/dapo/desktop/allica-repo` to enumerate the
current set — do not assume the list below is exhaustive or unchanged.

Most repos follow the `PET-<name>` prefix (Platform Engineering Team). The list below is
**auto-generated weekly** by `scripts/update_repo_list.sh` — do not edit between the markers by hand.

<!-- BEGIN AUTO-REPOS -->
_Last refreshed: 2026-07-01 · 13 repos_

- `PET-AI-Rules`
- `PET-container_app_environments`
- `PET-dns`
- `PET-gcp_governance`
- `PET-gcp_infra`
- `PET-ocr`
- `PET-pet_ai`
- `PET-pipelines`
- `PET-private_dns_resolver`
- `PET-private_endpoints`
- `PET-self-serv-storage`
- `PET-terraform_modules`
- `codebase`
<!-- END AUTO-REPOS -->

## Weekly Refresh
The repo list above is kept current by a script that runs once a week:

- Script: `ObsidianSkills/allica-repo-locations/scripts/update_repo_list.sh`
- Behaviour: lists immediate subdirectories of the repo root and rewrites the `AUTO-REPOS` block. Dry-run by default; `--apply` writes changes. Exits cleanly with no edit when nothing changed.
- Schedule: weekly via cron (Mondays 03:00), logging to `logs/repo-list-refresh.log`.
- Manual run: `bash ObsidianSkills/allica-repo-locations/scripts/update_repo_list.sh --apply`
- The script edits the file locally only; commit the refreshed list when you next commit (a `DOC:` or `CHORE:` change).

## Steps
1. When asked to find, read, clone, or work in an Allica platform repo, start from `/home/dapo/desktop/allica-repo`.
2. If the exact repo is unknown, run `ls -1 /home/dapo/desktop/allica-repo` and match by name.
3. For a specific repo, use `/home/dapo/desktop/allica-repo/<repo-name>`.
4. For agent behaviour rules (Jira/CMW/MCP/Terraform), read from `PET-AI-Rules/rules/` — the canonical source mirrored in this vault's `rules/`.
5. Never invent a path outside this root for Allica platform work; confirm with `ls` if unsure.

## Mode Selector
- `fast` (default): Return the repo root or a named repo path directly.
- `standard`: Repo name is ambiguous — `ls` the root and match, then return the path.
- `deep`: Multiple candidate repos or a cross-repo task — list the relevant repos and confirm scope before acting.

## Output Contract
- Mode: `<fast|standard|deep>`
- Repo Root: `/home/dapo/desktop/allica-repo`
- Resolved Path(s): the matched repo path(s)
- Notes: any ambiguity or follow-up needed

## Validation Checklist
- The returned path starts with `/home/dapo/desktop/allica-repo`.
- A named repo was confirmed to exist (via `ls`) before being used.
- Rule lookups point to `PET-AI-Rules/rules/` as the source of truth.

## Related
- [[ObsidianSkills/allica-repo-locations/allica-repo-locations|Allica Repo Locations Note]]
- [[My-Notes/PET-AI/pet-ai|PET-AI Note]]
- [[rules/jira-rules/jira-agent-rules|Jira Ticket Creation Agent Rules]]
