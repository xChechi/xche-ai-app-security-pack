#!/usr/bin/env bash
# xChe AI-App Security Pack — secret guard
# Runs before Bash commands. If gitleaks is installed and staged changes contain
# a secret, it blocks the action (exit 2). If gitleaks isn't installed, it skips
# silently so it never breaks a workflow.
set -euo pipefail

if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks protect --staged --no-banner >/dev/null 2>&1; then
    echo "BLOCKED by xChe security: staged changes contain a secret. Move it to an environment variable before committing." >&2
    exit 2
  fi
fi

exit 0
