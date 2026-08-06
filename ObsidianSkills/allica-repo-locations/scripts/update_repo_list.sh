#!/usr/bin/env bash
set -euo pipefail

# Refresh the auto-generated repo list inside the allica-repo-locations SKILL.md.
# Lists the immediate subdirectories of the Allica repo root and rewrites the block
# between the <!-- BEGIN AUTO-REPOS --> / <!-- END AUTO-REPOS --> markers.
# Dry-run by default; pass --apply to write changes. Intended to run weekly via cron.

VAULT_DIR="/mnt/c/my-vault"
REPO_ROOT="/home/dapo/desktop/allica-repo"
APPLY=0

usage() {
  echo "Usage: $0 [--apply] [--vault /path/to/vault] [--repo-root /path/to/repos]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --vault) VAULT_DIR="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

SKILL_FILE="$VAULT_DIR/ObsidianSkills/allica-repo-locations/SKILL.md"
BEGIN_MARKER="<!-- BEGIN AUTO-REPOS -->"
END_MARKER="<!-- END AUTO-REPOS -->"

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Repo root not found: $REPO_ROOT"
  exit 1
fi
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "SKILL file not found: $SKILL_FILE"
  exit 1
fi
if ! grep -qF "$BEGIN_MARKER" "$SKILL_FILE" || ! grep -qF "$END_MARKER" "$SKILL_FILE"; then
  echo "Markers not found in $SKILL_FILE — expected $BEGIN_MARKER / $END_MARKER"
  exit 1
fi

# Current repo list (immediate subdirectories, sorted).
mapfile -t repos < <(find "$REPO_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
count="${#repos[@]}"
today="$(date +%F)"

# Existing repo list already recorded between the markers (for change detection).
mapfile -t existing < <(sed -n "/$BEGIN_MARKER/,/$END_MARKER/p" "$SKILL_FILE" \
  | grep -E '^- `' | sed -E 's/^- `([^`]+)`.*/\1/' | sort)

# Diff old vs new.
added="$(comm -13 <(printf '%s\n' "${existing[@]}") <(printf '%s\n' "${repos[@]}") || true)"
removed="$(comm -23 <(printf '%s\n' "${existing[@]}") <(printf '%s\n' "${repos[@]}") || true)"

if [[ -z "$added" && -z "$removed" ]]; then
  echo "[$today] No repo changes. $count repos under $REPO_ROOT."
  exit 0
fi

echo "[$today] Repo list changes under $REPO_ROOT:"
[[ -n "$added" ]]   && echo "$added"   | sed 's/^/  + /'
[[ -n "$removed" ]] && echo "$removed" | sed 's/^/  - /'

if [[ $APPLY -eq 0 ]]; then
  echo "Dry run — re-run with --apply to update $SKILL_FILE"
  exit 0
fi

# Build the replacement block.
block_file="$(mktemp)"
{
  echo "$BEGIN_MARKER"
  echo "_Last refreshed: $today · $count repos_"
  echo ""
  for r in "${repos[@]}"; do
    echo "- \`$r\`"
  done
  echo "$END_MARKER"
} > "$block_file"

# Replace the region between the markers (inclusive) with the new block.
tmp="$(mktemp)"
awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v blockfile="$block_file" '
  $0 ~ begin {print_block(); skip=1}
  skip==1 {if ($0 ~ end) {skip=0}; next}
  {print}
  function print_block(){ while ((getline line < blockfile) > 0) print line; close(blockfile) }
' "$SKILL_FILE" > "$tmp"

mv "$tmp" "$SKILL_FILE"
rm -f "$block_file"
echo "[$today] Updated $SKILL_FILE ($count repos)."
