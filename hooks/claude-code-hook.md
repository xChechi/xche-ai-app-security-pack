# Optional: Claude Code PreToolUse hook

`CLAUDE.md` and `SECURITY.md` *guide* Claude Code, but they're advisory — they don't
hard-block anything. To turn a must-never rule into something that **can't happen**,
add a `PreToolUse` hook. It's the only hook that can block an action.

Below is a secret-commit guard: before any `Bash` command runs, it scans staged
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
          { "type": "command", "command": "./scripts/secret-guard.sh" }
        ]
      }
    ]
  }
}
```

## Layered enforcement (recommended)

You now have three nets, in order of how early they catch a leak:

1. **Claude Code hook** (this file) — before Claude even runs the commit command.
2. **pre-commit** (`.pre-commit-config.yaml`) — before the commit is created locally.
3. **CI gate** (`.github/workflows/security.yml`) — before the branch can merge.

Defense in depth: a secret has to slip past all three to reach production.
