---
name: github-ssh-dapo-setup
description: Configure per-repo SSH authentication for Dapo-code with an interactive, step-by-step script that asks before each action.
disable-model-invocation: true
---

# GitHub SSH Dapo Setup Skill

## Goal
Set up SSH authentication for this repo only so push access uses the Dapo-code identity without changing authentication behavior for other repositories.

## Scripts
- ObsidianSkills/github-ssh-dapo-setup/scripts/setup_repo_ssh_identity.sh
- ObsidianSkills/github-ssh-dapo-setup/scripts/restore_https_remote.sh

## Usage
1. Run the interactive setup script from the repo root:

```bash
bash /mnt/c/my-vault/ObsidianSkills/github-ssh-dapo-setup/scripts/setup_repo_ssh_identity.sh
```

2. Follow prompts. Every step asks if you want to continue.
3. If needed, restore `origin` to HTTPS with the rollback script:

```bash
bash /mnt/c/my-vault/ObsidianSkills/github-ssh-dapo-setup/scripts/restore_https_remote.sh
```

## What This Changes
- Creates a dedicated SSH key for Dapo-code (or reuses existing key).
- Adds a host alias in `~/.ssh/config`.
- Updates this repository's `origin` remote to that alias only.
- Tests SSH authentication and optionally pushes current branch.

## Validation
- `git remote -v` in this repo shows `git@github-dapo-code:...`.
- `ssh -T git@github-dapo-code` authenticates as the correct account.
- `git push -u origin <branch>` succeeds.

## Related
- [[Oladapo]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
