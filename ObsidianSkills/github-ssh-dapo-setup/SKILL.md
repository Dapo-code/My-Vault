---
name: github-ssh-dapo-setup
description: Configure per-repo SSH authentication for Dapo-code with an interactive, step-by-step script that asks before each action.
disable-model-invocation: true
---

# GitHub SSH Dapo Setup Skill

## Goal
Set up SSH authentication for this repo only so push access uses the Dapo-code identity without changing authentication behavior for other repositories.

## Required Parameters
Collect these before running this skill:

1. repo_root
- Absolute path to repository root.

2. setup_script_path
- Path to `setup_repo_ssh_identity.sh`.

3. rollback_script_path
- Path to `restore_https_remote.sh`.

4. github_alias
- SSH host alias to configure (for example `github-dapo-code`).

## Optional Parameters
1. run_push_test
- Boolean to run a push test after setup.

2. target_branch
- Branch name for optional push test.

3. reuse_existing_key
- Boolean indicating whether existing key material may be reused.

## Parameter Rules
1. Do not run setup if any required path parameter is missing.
2. Confirm each interactive action before execution.
3. Do not modify authentication behavior for unrelated repositories.
4. Use rollback script when restoration to HTTPS is requested.

## Scripts
- ObsidianSkills/github-ssh-dapo-setup/scripts/setup_repo_ssh_identity.sh
- ObsidianSkills/github-ssh-dapo-setup/scripts/restore_https_remote.sh

## Usage
1. Validate required parameters.
2. Run the interactive setup script from `repo_root`:

```bash
bash /mnt/c/my-vault/ObsidianSkills/github-ssh-dapo-setup/scripts/setup_repo_ssh_identity.sh
```

3. Follow prompts. Every step asks if you want to continue.
4. If requested, run SSH auth and optional push tests.
5. If needed, restore `origin` to HTTPS with the rollback script:

```bash
bash /mnt/c/my-vault/ObsidianSkills/github-ssh-dapo-setup/scripts/restore_https_remote.sh
```

## What This Changes
- Creates a dedicated SSH key for Dapo-code (or reuses existing key).
- Adds a host alias in `~/.ssh/config`.
- Updates this repository's `origin` remote to that alias only.
- Tests SSH authentication and optionally pushes current branch.

## Validation
- All required parameters were provided.
- `git remote -v` in this repo shows `git@github-dapo-code:...`.
- `ssh -T git@github-dapo-code` authenticates as the correct account.
- `git push -u origin <branch>` succeeds.

## Related
- [[ObsidianSkills/github-ssh-dapo-setup/github-ssh-dapo-setup|GitHub SSH Dapo Setup Skill Note]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
