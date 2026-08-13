# Vault Agent Instructions

This is a folder-based Obsidian vault at `/mnt/c/my-vault`.

## Skill-First Rule
Before creating notes, files, or running any vault workflow, always check `ObsidianSkills/` for a matching SKILL.md. Use the canonical index at `ObsidianSkills/skill-list.md` to find the right skill.

## Available Skills

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
| Log branch work (ticket, summary, PR) | `ObsidianSkills/work-log/SKILL.md` |

## Rules
- Read the matching SKILL.md before acting — do not guess at format or structure.
- Frontmatter (`created`, `updated`, `title`, `tags`) is required on all notes.
- Always refresh `updated` when editing an existing note.
- Route changelog entries through the changelog-maintenance skill.
- Route skill index changes through the index-update skill.
