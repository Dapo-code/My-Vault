---
name: vm-container-health-check
description: SSH into an Azure VM via az ssh and inspect running Docker containers for health — read-only, no remediation actions.
---

# VM Container Health Check Skill

## Goal
Given a VM IP address or name, connect via `az ssh vm` and verify all Docker containers are running. Report status only — take no corrective action under any circumstances.

## Prerequisites
- `az` CLI installed and authenticated (`az login` or managed identity active).
- `az ssh` extension installed: `az extension add --name ssh`.
- Target VM must be accessible via Azure Arc or direct IP.

## Steps
1. Confirm az CLI and ssh extension are ready: `az version` and `az extension list --query "[?name=='ssh']"`.
2. **Fast path (IP known):** `az ssh vm --ip <vm-ip>`
   **Standard path (name known, IP unknown):** retrieve IP first:
   `az vm show -g <resource-group> -n <vm-name> --show-details --query publicIps -o tsv`
   then connect with `az ssh vm --ip <resolved-ip>`.
3. Once connected, run: `sudo docker ps`
   - Plain `docker ps` will fail with permission denied on this platform — always use `sudo`.
4. Scan output for containers **not** in `Up` state (e.g. `Exited`, `Restarting`, `Created`).
5. If deeper inspection is needed (deep mode only), run these read-only commands:
   - `sudo docker inspect <container-id>` — config and state detail.
   - `sudo docker logs --tail 50 <container-id>` — last 50 log lines.
   - `sudo systemctl status docker` — daemon-level status.
6. Compile and return the Output Contract block below.
7. Exit the SSH session: `exit`.

## Guardrails — NEVER run these
- `docker stop` / `docker restart` / `docker kill` / `docker rm`
- Any `sudo` command not listed in Step 3 or Step 5.
- Do not attempt password-based SSH fallback if `az ssh vm` fails — report the failure and stop.

## Mode Selector
- `fast` (default): VM IP supplied directly. Connect → `sudo docker ps` → report. One SSH session.
- `standard`: VM name supplied, IP unknown. Resolve IP via `az vm show`, then follow fast path.
- `deep`: Containers in non-`Up` state, or user requests log inspection. Run Step 5 commands (read-only). Still no remediation.

### Deep Mode Triggers
- One or more containers not in `Up` state.
- User explicitly requests log or inspect data.

## Output Contract
```
VM: <ip>          Connection: OK | FAILED
Containers found: <n>

  [HEALTHY]  <container-name> | <image> | Up <uptime>
  [DEGRADED] <container-name> | <image> | <status>

Action taken: None
```
If connection fails, output:
```
VM: <ip>  Connection: FAILED — <error summary>
Action taken: None
```

## Validation Checklist
- `az ssh vm` connected without error before any docker commands were run.
- `sudo docker ps` used (not plain `docker ps`) — avoids permission-denied failure.
- Every container in the output is reported; none silently skipped.
- No docker stop / restart / rm / kill commands were issued.
- Output matches the Output Contract format exactly.

## Related
- [[ObsidianSkills/vm-container-health-check/vm-container-health-check|VM Container Health Check Note]]
- [[ObsidianSkills/allica-repo-locations/allica-repo-locations|Allica Repo Locations]]
