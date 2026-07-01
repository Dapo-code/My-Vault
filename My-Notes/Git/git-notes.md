---
title: Git Notes
tags:
  - git
  - reference
created: 2026-06-16
updated: 2026-07-01
status: evergreen
type: note
---

# Git Notes

## Pointing branch to submodules main/branch
- To check which branch the top module is pointing to in the submodule:
    - `git submodule status`
- Checkout submodule to main/branch
- Update submodule to main/branch:
    - `git submodule update --remote --merge Terraform/shared`
    - `git add Terraform/shared`
    - `git commit -m "chore: update shared submodule to latest main"`

## Prune branches
- `git branch | grep -v -E "(main|master|develop|\*)" | xargs git branch -d`

## Git logs
- Get the logs in a pretty format (lists commits from the first history):
    - `git log --pretty=format:"-%s" --reverse`
    - `git log --pretty=format:"% - %s (%an, %ar)" --reverse`

## Related
- [[My-Notes/my-notes|My Notes Folder Guide]]
- [[rules/github-rules/github-agent-rules|GitHub Agent Commit and Push Rules]]
