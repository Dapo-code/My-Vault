#!/usr/bin/env bash
set -euo pipefail

# Called by the post-checkout hook. Creates a stub work-log note if one doesn't already exist.

VAULT_DIR="/mnt/c/my-vault"
REPO_NAME="${1:-}"
BRANCH_NAME="${2:-}"

if [[ -z "$REPO_NAME" || -z "$BRANCH_NAME" ]]; then
  echo "Usage: $0 <repo_name> <branch_name>" >&2
  exit 1
fi

NOTE_PATH="$VAULT_DIR/My-Notes/Work-Log/$REPO_NAME/$BRANCH_NAME.md"

# Idempotent — nothing to do if the note already exists
[[ -f "$NOTE_PATH" ]] && exit 0

mkdir -p "$(dirname "$NOTE_PATH")"

TODAY=$(date +%F)

cat > "$NOTE_PATH" <<EOF
---
title: $BRANCH_NAME
tags:
  - work-log
  - $REPO_NAME
created: $TODAY
updated: $TODAY
status: in-progress
---

# $BRANCH_NAME

## Branch Info
- **Repo:** $REPO_NAME
- **Branch:** $BRANCH_NAME
- **Jira Ticket:**
- **Ticket Title:**
- **PR Link:**

## Work Summary


## Key Changes


## Notes / Learnings
EOF

echo "[$(date +%FT%T)] work-log: created $NOTE_PATH"
