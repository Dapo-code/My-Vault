#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="${1:-$PWD}"
KEY_PATH="${HOME}/.ssh/dapo-code-my-vault"
PUB_KEY_PATH="${KEY_PATH}.pub"
SSH_CONFIG="${HOME}/.ssh/config"
HOST_ALIAS="github-dapo-code"
TARGET_REPO="Dapo-code/My-Vault.git"

step_prompt() {
  local prompt_text="$1"
  local answer
  while true; do
    read -r -p "${prompt_text} [y/n/q]: " answer
    case "${answer}" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      q|Q)
        echo "Exiting by user request."
        exit 0
        ;;
      *)
        echo "Please enter y, n, or q."
        ;;
    esac
  done
}

echo "Repo-scoped GitHub SSH setup for Dapo-code"
echo "Repo: ${REPO_DIR}"
echo

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  echo "Error: ${REPO_DIR} is not a git repository."
  exit 1
fi

cd "${REPO_DIR}"

if step_prompt "Step 1: Show current remote and branch?"; then
  git remote -v
  git branch --show-current
  echo
fi

if [[ ! -f "${KEY_PATH}" || ! -f "${PUB_KEY_PATH}" ]]; then
  if step_prompt "Step 2: Generate dedicated SSH key at ${KEY_PATH}?"; then
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    ssh-keygen -t ed25519 -f "${KEY_PATH}" -C "dapo-code-my-vault" -N ""
    echo "SSH key generated."
    echo
  fi
else
  echo "Step 2: SSH key already exists at ${KEY_PATH}."
  echo
fi

if [[ ! -f "${PUB_KEY_PATH}" ]]; then
  echo "Error: missing public key file ${PUB_KEY_PATH}."
  exit 1
fi

if step_prompt "Step 3: Print public key so you can add it to GitHub (Dapo-code account)?"; then
  echo
  cat "${PUB_KEY_PATH}"
  echo
  echo "Add this key at: https://github.com/settings/keys"
  read -r -p "Press Enter after adding the key in GitHub..."
  echo
fi

if step_prompt "Step 4: Ensure SSH config has host alias ${HOST_ALIAS}?"; then
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  touch "${SSH_CONFIG}"
  chmod 600 "${SSH_CONFIG}"

  if ! grep -qE "^Host[[:space:]]+${HOST_ALIAS}$" "${SSH_CONFIG}"; then
    {
      echo ""
      echo "Host ${HOST_ALIAS}"
      echo "    HostName github.com"
      echo "    User git"
      echo "    IdentityFile ${KEY_PATH}"
      echo "    IdentitiesOnly yes"
    } >> "${SSH_CONFIG}"
    echo "Added host alias ${HOST_ALIAS} to ${SSH_CONFIG}."
  else
    echo "Host alias ${HOST_ALIAS} already exists in ${SSH_CONFIG}."
  fi
  echo
fi

if step_prompt "Step 5: Set this repo's origin to SSH alias (repo-only change)?"; then
  git remote set-url origin "git@${HOST_ALIAS}:${TARGET_REPO}"
  echo "Updated origin URL."
  git remote -v
  echo
fi

if step_prompt "Step 6: Test SSH authentication via ${HOST_ALIAS}?"; then
  set +e
  ssh -T "git@${HOST_ALIAS}"
  ssh_exit_code=$?
  set -e
  if [[ ${ssh_exit_code} -ne 0 && ${ssh_exit_code} -ne 1 ]]; then
    echo "SSH test failed with exit code ${ssh_exit_code}."
    echo "Check key setup and GitHub account key registration."
    exit ${ssh_exit_code}
  fi
  echo
fi

current_branch="$(git branch --show-current)"
if [[ -z "${current_branch}" ]]; then
  current_branch="master"
fi

if step_prompt "Step 7: Push current branch (${current_branch}) with upstream tracking?"; then
  git push -u origin "${current_branch}"
  echo "Push complete."
  echo
fi

echo "Done. Any skipped steps can be re-run by executing this script again."
