#!/usr/bin/env bash
# xChe AI-App Security Pack — secret guard
# Wired as a PreToolUse hook scoped to `git commit` (see hooks.json `if`). If
# gitleaks is installed and the STAGED changes contain a secret, it blocks the
# commit (exit 2). It deliberately fails OPEN: if gitleaks is absent or errors,
# it does NOT block — this is the weakest, convenience net; the pre-commit hook
# and the CI gate are the real guarantees.
set -euo pipefail

if command -v gitleaks >/dev/null 2>&1; then
  code=0
  # `git --pre-commit --staged` is the current gitleaks invocation (protect/detect
  # were deprecated in v8.19). Output suppressed; we act on the exit code only.
  gitleaks git --pre-commit --redact --staged >/dev/null 2>&1 || code=$?
  # gitleaks: 0 = clean, 1 = leaks found, other = tooling error. Block ONLY on a
  # real finding (1) so a deprecated/removed subcommand can't false-block commits.
  if [ "$code" -eq 1 ]; then
    echo "BLOCKED by xChe security: staged changes contain a secret. Move it to an environment variable before committing." >&2
    exit 2
  fi
fi

exit 0
