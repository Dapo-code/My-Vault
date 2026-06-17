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

## Git logs
* getting the logs in a pretty format
    - git log --pretty=format:"-%s" --reverse 

## Links
- [[ObsidianSkills/daily-notes/daily-notes|Daily Notes Skill Note]]
