---
title: Skills Change Log
tags:
  - changelog
  - skills
  - vault
created: 2026-06-08
updated: 2026-08-06
---

# Skills Change Log

Track changes related to skills under `ObsidianSkills` only.

## Scope
Use this changelog for skill-specific updates such as:
- New skill folders
- New or updated `SKILL.md` files
- New or updated top-level skill note files
- Skill script changes
- Skill policy and workflow changes

## Entries

- 2026-08-06: Added `vm-container-health-check` skill — SSH into Azure VMs via `az ssh vm` and inspect Docker container health (read-only). Captures lessons from live troubleshooting: use `sudo docker ps` (plain docker ps hits permission denied), upgrade az ssh extension for ARC VMs < 2.0.4.
- 2026-07-03: Added `update_repo_list.sh` to the allica-repo-locations skill — regenerates the marker-delimited repo list in SKILL.md and is scheduled weekly via cron (Mondays 03:00, logs to `logs/repo-list-refresh.log`).
- 2026-07-01: Added allica-repo-locations skill recording the local Allica platform (PET) repo root `/home/dapo/desktop/allica-repo`; indexed in skill-list.md and CLAUDE.md.
- 2026-07-01: Aligned github-commit-push SKILL.md commit prefixes with the `commit-msg` hook — single-word `SKILL`/`DOC`/`FIX`/`CHORE`/`FEAT` (was `SKILL UPDATE`/`DOC UPDATE`); mirrored in github-agent-rules and CLAUDE.md.
- 2026-06-09: Removed `Work Log` from ObsidianSkills/skill-list.md and updated index policies so all skill-list changes are logged only in ObsidianSkills/skills-changelog.md.
- 2026-06-09: Retrofitted operational skills to include Mode Selector, Output Contract, and Stop Rules for consistent low-token execution patterns.
- 2026-06-09: Added token-optimization-standard skill and updated skill-format-guide so all new skills require mode selector, output contract, and low-token validation rules.

- 2026-06-08: Created a dedicated changelog for skills under ObsidianSkills.
- 2026-06-08: Updated changelog-maintenance policy and Oladapo index wording to route skill-related updates to the skills changelog.
- 2026-06-08: Updated all skill notes and SKILL.md files to link to the skills changelog instead of the top-level changelog.
- 2026-06-08: Removed direct main-changelog wiki links from skill notes so skills now point only to the skills changelog.
- 2026-06-08: Marked skill-format-guide as the canonical guide for creating future skills and linked it from all skill notes.
- 2026-06-08: Simplified folder-level skill notes to a minimal description plus links to the canonical skill format guide and local SKILL.md.
- 2026-06-08: Removed the legacy ObsidianSkills/skill.md and ObsidianSkills/daily-notes-skill.md files after migrating to folder-based skill notes.
- 2026-06-08: Added github-ssh-dapo-setup skill with interactive scripts to configure repo-scoped Dapo-code SSH authentication and optional HTTPS remote rollback.
- 2026-06-08: Added github-commit-push skill that references rules/github-rules/github-agent-rules.md for consistent commit/push behavior and SKILL UPDATE style commit subjects.

## Related
- [[Oladapo]]
- [[ObsidianSkills/changelog-maintenance/changelog-maintenance|Changelog Maintenance Skill]]
