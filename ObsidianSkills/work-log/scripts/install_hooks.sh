#!/usr/bin/env bash
set -euo pipefail

# One-time installer: writes the post-checkout work-log hook into every Allica repo's .git/hooks/
# and deploys work-log.instructions.md (local-only, git-excluded) to .github/instructions/.
# Dry-run by default — pass --apply to write.
# Safety guard: if core.hooksPath points outside .git/, the repo is skipped with a warning.

REPO_ROOT="/home/dapo/desktop/allica-repo"
VAULT_DIR="/mnt/c/my-vault"
APPLY=0
FORCE=0

INSTRUCTIONS_TEMPLATE="$VAULT_DIR/ObsidianSkills/work-log/templates/work-log.instructions.md"
INSTRUCTIONS_SIG="# Work Log Instructions"
HOOK_SIGNATURE="# post-checkout: create vault work-log stub"

# Written verbatim into each repo's .git/hooks/post-checkout
read -r -d '' HOOK_CONTENT <<'HOOK' || true
#!/usr/bin/env bash
# post-checkout: create vault work-log stub
[ "$3" = "1" ] || exit 0
BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in main|master|develop|development|HEAD) exit 0 ;; esac
REPO=$(basename "$(git rev-parse --show-toplevel)")
SCRIPT="/mnt/c/my-vault/ObsidianSkills/work-log/scripts/create_branch_note.sh"
[ -x "$SCRIPT" ] && bash "$SCRIPT" "$REPO" "$BRANCH"
HOOK

usage() {
  echo "Usage: $0 [--apply] [--force] [--repo-root /path/to/repos]"
  echo "  --apply      Write hooks and instructions (default: dry-run)"
  echo "  --force      Overwrite existing managed hooks/instructions (use after template changes)"
  echo "  --repo-root  Override default repo root"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)     APPLY=1; shift ;;
    --force)     FORCE=1; shift ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

[[ -d "$REPO_ROOT" ]] || { echo "ERROR: Repo root not found: $REPO_ROOT"; exit 1; }

installed=0; skipped=0; warned=0

for repo_dir in "$REPO_ROOT"/*/; do
  [[ -d "$repo_dir/.git" ]] || continue
  repo_dir="${repo_dir%/}"
  repo_name=$(basename "$repo_dir")

  # Safety guard: check for an overridden hooksPath
  hooks_path=$(git -C "$repo_dir" config core.hooksPath 2>/dev/null || true)
  if [[ -n "$hooks_path" ]]; then
    [[ "$hooks_path" = /* ]] || hooks_path="$repo_dir/$hooks_path"
    if [[ "$hooks_path" != "$repo_dir/.git"* ]]; then
      echo "[WARN]    $repo_name: core.hooksPath='$hooks_path' is outside .git/ — skipping (would commit hook)"
      ((warned++)) || true
      continue
    fi
    hook_dir="$hooks_path"
  else
    hook_dir="$repo_dir/.git/hooks"
  fi

  hook_file="$hook_dir/post-checkout"
  install_hook=1

  if [[ -f "$hook_file" ]] && grep -qF "$HOOK_SIGNATURE" "$hook_file" 2>/dev/null; then
    if [[ "$FORCE" -eq 0 ]]; then
      echo "[SKIP]    $repo_name: hook already installed (use --force to overwrite)"
      ((skipped++)) || true
      install_hook=0
    else
      echo "[FORCE]   $repo_name → $hook_file"
    fi
  elif [[ -f "$hook_file" ]]; then
    echo "[WARN]    $repo_name: $hook_file exists but not managed by work-log — skipping hook"
    ((warned++)) || true
    install_hook=0
  else
    echo "[INSTALL] $repo_name → $hook_file"
  fi

  if [[ "$install_hook" -eq 1 && "$APPLY" -eq 1 ]]; then
    mkdir -p "$hook_dir"
    printf '%s\n' "$HOOK_CONTENT" > "$hook_file"
    chmod +x "$hook_file"
    ((installed++)) || true
  fi

  # Deploy local-only Copilot instructions file (git-excluded via .git/info/exclude)
  instr_dir="$repo_dir/.github/instructions"
  instr_file="$instr_dir/work-log.instructions.md"
  exclude_file="$repo_dir/.git/info/exclude"

  if [[ -f "$instr_file" ]] && grep -qF "$INSTRUCTIONS_SIG" "$instr_file" 2>/dev/null && [[ "$FORCE" -eq 0 ]]; then
    echo "[SKIP]    $repo_name: instructions already deployed"
  elif [[ -f "$instr_file" && "$FORCE" -eq 0 ]]; then
    echo "[WARN]    $repo_name: $instr_file exists but not ours — skipping instructions"
    ((warned++)) || true
  else
    echo "[INSTR]   $repo_name → $instr_file"
    if [[ "$APPLY" -eq 1 ]]; then
      mkdir -p "$instr_dir"
      cp "$INSTRUCTIONS_TEMPLATE" "$instr_file"
      # Register in local exclude so git never stages or commits this file
      if ! grep -qF ".github/instructions/work-log.instructions.md" "$exclude_file" 2>/dev/null; then
        echo ".github/instructions/work-log.instructions.md" >> "$exclude_file"
      fi
    fi
  fi

done

echo ""
if [[ "$APPLY" -eq 0 ]]; then
  echo "Dry-run complete. Pass --apply to write hooks and instructions."
else
  echo "Done — installed=$installed  skipped=$skipped  warned=$warned"
fi
