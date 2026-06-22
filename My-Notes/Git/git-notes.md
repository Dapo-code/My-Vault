---
title: Git Notes
tags:
  - daily
  - git
created: 2026-06-16
updated: 2026-06-16
---

# Git Notes

## Pointing branch to submodules main/branch
* To check which branch the top module is poitning  to in the submodule use 
    - git submodule status
* Checkout submodule to main/branch

* update submodule to main/branch
    - git submodule update --remote --merge Terraform/shared
    - git add Terraform/shared
    - git commit -m "chore: update shared submodule to latest main"

## Prune branches
- git branch | grep -v -E "(main|master|develop|\*)" | xargs git branch -d

## Git logs
* getting the logs in a pretty format: this gives you the list of commits from the first history
    - git log --pretty=format:"-%s" --reverse 
    - git log --pretty=format:"% - %s (%an, %ar)" --reverse

## Links
- [[ObsidianSkills/daily-notes/daily-notes|Daily Notes Skill Note]]
