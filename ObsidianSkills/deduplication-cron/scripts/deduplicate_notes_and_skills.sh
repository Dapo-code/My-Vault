#!/usr/bin/env bash
set -euo pipefail

VAULT_DIR="/mnt/c/my-vault"
APPLY=0

usage() {
  echo "Usage: $0 [--apply] [--vault /path/to/vault]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    --vault)
      VAULT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -d "$VAULT_DIR" ]]; then
  echo "Vault not found: $VAULT_DIR"
  exit 1
fi

# Build duplicate groups by normalized markdown filename.
declare -A groups
while IFS= read -r file; do
  base_name="$(basename "$file" .md)"
  if [[ "$(basename "$file")" == "SKILL.md" ]]; then
    parent_name="$(basename "$(dirname "$file")")"
    key="skill::$(echo "$parent_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+//g')"
  else
    key="note::$(echo "$base_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+//g')"
  fi
  groups["$key"]+="$file"$'\n'
done < <(find "$VAULT_DIR" -type f -name "*.md" ! -path "$VAULT_DIR/.obsidian/*" | sort)

replace_links() {
  local old_path_no_ext="$1"
  local new_path_no_ext="$2"
  local old_base="$3"
  local new_base="$4"

  while IFS= read -r md; do
    sed -i "s|\[\[$old_path_no_ext\||\[\[$new_path_no_ext\||g" "$md"
    sed -i "s|\[\[$old_path_no_ext#|\[\[$new_path_no_ext#|g" "$md"
    sed -i "s|\[\[$old_path_no_ext\]\]|\[\[$new_path_no_ext\]\]|g" "$md"

    if [[ "$old_base" != "$new_base" ]]; then
      sed -i "s|\[\[$old_base\||\[\[$new_base\||g" "$md"
      sed -i "s|\[\[$old_base#|\[\[$new_base#|g" "$md"
      sed -i "s|\[\[$old_base\]\]|\[\[$new_base\]\]|g" "$md"
    fi
  done < <(find "$VAULT_DIR" -type f -name "*.md" ! -path "$VAULT_DIR/.obsidian/*")
}

merge_file_into_canonical() {
  local canonical="$1"
  local duplicate="$2"
  local stamp="$3"
  local rel_dup="${duplicate#"$VAULT_DIR"/}"

  # Skip if files are already byte-identical.
  if cmp -s "$canonical" "$duplicate"; then
    echo "Identical duplicate found: $duplicate -> $canonical"
    if [[ $APPLY -eq 1 ]]; then
      rm -f "$duplicate"
      echo "Removed identical duplicate: $duplicate"
    fi
    return
  fi

  echo "Merge required: $duplicate -> $canonical"
  if [[ $APPLY -eq 1 ]]; then
    {
      printf "\n\n## Merged from %s on %s\n\n" "$rel_dup" "$stamp"
      cat "$duplicate"
      printf "\n"
    } >> "$canonical"

    old_no_ext="${rel_dup%.md}"
    new_rel="${canonical#"$VAULT_DIR"/}"
    new_no_ext="${new_rel%.md}"
    old_base="$(basename "$old_no_ext")"
    new_base="$(basename "$new_no_ext")"

    replace_links "$old_no_ext" "$new_no_ext" "$old_base" "$new_base"

    rm -f "$duplicate"
    echo "Merged and removed duplicate: $duplicate"
  fi
}

date_stamp="$(date +%F)"
changes=0

for key in "${!groups[@]}"; do
  mapfile -t files < <(printf "%s" "${groups[$key]}" | sed '/^$/d' | sort)
  if (( ${#files[@]} < 2 )); then
    continue
  fi

  # Prefer files in ObsidianSkills as canonical for skill groups.
  canonical="${files[0]}"
  if [[ "$key" == skill::* ]]; then
    for candidate in "${files[@]}"; do
      if [[ "$candidate" == *"/ObsidianSkills/"* ]]; then
        canonical="$candidate"
        break
      fi
    done
  fi

  for dup in "${files[@]}"; do
    if [[ "$dup" == "$canonical" ]]; then
      continue
    fi
    merge_file_into_canonical "$canonical" "$dup" "$date_stamp"
    changes=$((changes + 1))
  done
done

if [[ $APPLY -eq 1 ]]; then
  echo "Deduplication complete. Merge operations: $changes"
else
  echo "Dry run complete. Potential merge operations: $changes"
  echo "Run with --apply to perform merges and remove duplicates."
fi
