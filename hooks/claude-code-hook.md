# Optional: Claude Code PreToolUse hook

`CLAUDE.md` and `SECURITY.md` *guide* Claude Code, but they're advisory — they don't
hard-block anything. To turn a must-never rule into something that **can't happen**,
add a `PreToolUse` hook. It's the only hook that can block an action.

Below is a secret-commit guard: when Claude runs a `git commit`, it scans the staged
changes for secrets and blocks the commit if any are found.

> ⚠️ Claude Code's hook schema evolves. Confirm the exact settings format against the
> official docs before relying on this: https://code.claude.com/docs/en/hooks

## 1. The guard script — `scripts/secret-guard.sh`

```bash
#!/usr/bin/env bash
# Blocks if staged changes contain secrets. Requires gitleaks installed.
set -euo pipefail
if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks protect --staged --no-banner; then
    echo "BLOCKED: staged changes contain a secret. Move it to an env var." >&2
    exit 2   # non-zero exit signals the hook to block the action
  fi
fi
exit 0
```
Make it executable: `chmod +x scripts/secret-guard.sh`

## 2. Wire it in `~/.claude/settings.json` (user-level) or `.claude/settings.json` (project)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "if": "Bash(git commit:*)", "command": "./scripts/secret-guard.sh" }
        ]
      }
    ]
  }
}
```

> Note: the `matcher` filters by **tool name** (`"Bash"`); the `if` field scopes by command (here, only `git commit`). Putting `Bash(git commit:*)` in `matcher` instead would never fire.

## Layered enforcement (recommended)

Three nets — but they are **not equal**. Install all three; the bottom two are the real gates:

1. **pre-commit** (`.pre-commit-config.yaml`) — **primary local gate.** Covers *all* local commits regardless of tool, and catches `git commit -am` (it runs at the real commit moment).
2. **CI gate** (`.github/workflows/security.yml`) — **hard backstop.** Runs on every push/PR and can't be bypassed; this is what ultimately stops a secret reaching the remote.
3. **Claude Code hook** (this file) — **convenience only.** Fires just for commits Claude Code itself runs (not your terminal or IDE), and can miss `-am`. Catches the common "Claude committed a key" case early — not a guarantee.
