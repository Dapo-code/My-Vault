---
title: VM Container Health Check Skill
tags:
  - skill
  - azure
  - docker
  - vm
  - health-check
created: 2026-08-06
updated: 2026-08-06
---

# VM Container Health Check Skill

Read-only skill for SSH-ing into an Azure VM via `az ssh vm` and verifying the health of running Docker containers. Provide a VM IP or name; the skill resolves the connection and reports container status. No corrective actions are ever taken.

## Usage
- Provide the VM IP address (fast path) or VM name + resource group (standard path).
- The skill connects via `az ssh vm --ip <ip>`, runs `sudo docker ps`, and returns a structured status report.
- If containers are degraded, deep mode inspects logs and config — still read-only.

## Key Lessons (from live troubleshooting 2026-08-06)
- Plain `docker ps` returns permission denied on this platform — always use `sudo docker ps`.
- `az ssh vm` may display a deprecation warning for ARC machines on versions < 2.0.4; upgrade the ssh extension when prompted.
- All 5 containers on `abl-prod-iam-pd-2-vm` (192.168.81.69) reported healthy at `Up 9 minutes` during this session.

## Skill Definition
[[ObsidianSkills/vm-container-health-check/SKILL|Open SKILL.md]]

## Related
- [[ObsidianSkills/allica-repo-locations/allica-repo-locations|Allica Repo Locations]]
