#!/usr/bin/env bash
set -euo pipefail

# Cron-driven sync: installs the work-log post-checkout hook in any Allica repos that
# don't have it yet (e.g. newly cloned repos). Scheduled weekly on Mondays at 10:00.
# Modelled on ObsidianSkills/allica-repo-locations/scripts/update_repo_list.sh.

REPO_ROOT="/home/dapo/desktop/allica-repo"
VAULT_DIR="/mnt/c/my-vault"
LOG_FILE="$VAULT_DIR/logs/work-log-hook-sync.log"

HOOK_SIGNATURE="# post-checkout: create vault work-log stub"

read -r -d '' HOOK_CONTENT <<'HOOK' || true
#!/usr/bin/env bash
# post-checkout: create vault work-log stub
[ "$3" = "1" ] || exit 0
BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in main|master|develop|development) exit 0 ;; esac
REPO=$(basename "$(git rev-parse --show-toplevel)")
SCRIPT="/mnt/c/my-vault/ObsidianSkills/work-log/scripts/create_branch_note.sh"
[ -x "$SCRIPT" ] && bash "$SCRIPT" "$REPO" "$BRANCH"
HOOK

log() {
  local msg="[$(date +%FT%T)] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

[[ -d "$REPO_ROOT" ]] || { log "ERROR: Repo root not found: $REPO_ROOT"; exit 1; }
mkdir -p "$(dirname "$LOG_FILE")"

installed=0; skipped=0; warned=0

for repo_dir in "$REPO_ROOT"/*/; do
  [[ -d "$repo_dir/.git" ]] || continue
  repo_dir="${repo_dir%/}"
  repo_name=$(basename "$repo_dir")

  hooks_path=$(git -C "$repo_dir" config core.hooksPath 2>/dev/null || true)
  if [[ -n "$hooks_path" ]]; then
    [[ "$hooks_path" = /* ]] || hooks_path="$repo_dir/$hooks_path"
    if [[ "$hooks_path" != "$repo_dir/.git"* ]]; then
      log "WARN $repo_name: core.hooksPath='$hooks_path' outside .git/ — skipping"
      ((warned++)) || true
      continue
    fi
    hook_dir="$hooks_path"
  else
    hook_dir="$repo_dir/.git/hooks"
  fi

  hook_file="$hook_dir/post-checkout"

  # Already managed by us — nothing to do
  if [[ -f "$hook_file" ]] && grep -qF "$HOOK_SIGNATURE" "$hook_file" 2>/dev/null; then
    ((skipped++)) || true
    continue
  fi

  # Conflict: pre-existing hook not ours — don't overwrite silently
  if [[ -f "$hook_file" ]]; then
    log "WARN $repo_name: $hook_file exists but not managed by work-log — skipping"
    ((warned++)) || true
    continue
  fi

  mkdir -p "$hook_dir"
  printf '%s\n' "$HOOK_CONTENT" > "$hook_file"
  chmod +x "$hook_file"
  log "INSTALLED hook in $repo_name"
  ((installed++)) || true
done

log "Sync complete — installed=$installed skipped=$skipped warned=$warned"
