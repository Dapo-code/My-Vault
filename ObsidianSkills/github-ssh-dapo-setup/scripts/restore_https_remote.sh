#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="${1:-$PWD}"
HTTPS_URL="https://github.com/Dapo-code/My-Vault.git"

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  echo "Error: ${REPO_DIR} is not a git repository."
  exit 1
fi

cd "${REPO_DIR}"
git remote set-url origin "${HTTPS_URL}"

echo "Origin remote restored to HTTPS for this repository only:"
git remote -v
