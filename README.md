# xChe AI-App Security Pack

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)
![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-8A2BE2)
![Status: Active](https://img.shields.io/badge/status-active-success)

> **Free, opinionated security guardrails for apps built with AI coding tools** — Claude Code, Cursor, Lovable, Bolt, Codex — so the speed doesn't ship you a breach.

Drop-in `CLAUDE.md` rules, a full OWASP / API / LLM / MCP security policy, plus secret-scanning hooks and a CI gate. Hardens your AI coding setup against the exact bug classes behind every "vibe-coded app leaked its database" headline — **before the code is written.**

---

## Why this exists

AI coding tools generate **working** code, not **secure** code. The result is now a recurring headline:

- A fully AI-built social app exposed **1.5M API keys + 35k emails** within days of launch.
- A $1M habit app had its database **publicly readable** — all 39k users exposed.
- Studies put **40–62%** of AI-generated code as carrying at least one security flaw.

The bugs are almost always the same handful: hardcoded secrets, broken access control, missing input validation, exposed databases, no security headers. This pack hardens your setup against exactly those.

## What's inside

| File | What it does |
|------|--------------|
| `AGENTS.md` | Condensed rules in the **cross-tool standard** — read by Cursor, Codex, Copilot, Gemini CLI, Aider, Windsurf & 25+ agents. |
| `CLAUDE.md` | The same rules + Claude-specifics — drop into your global `~/.claude/CLAUDE.md` so **every** project inherits them. |
| `SECURITY.md` | The full policy — OWASP Top 10 + API Top 10 + LLM/MCP Top 10 + cloud/infra rules. |
| `plugins/ai-app-security/` | A **Claude Code plugin**: a `secure-coding` skill (applies the rules *while building*) + an `/audit` skill (manual full review) + a hook that blocks secret commits. One-command install. |
| `.pre-commit-config.yaml` | A git pre-commit hook that scans for secrets (gitleaks). |
| `.github/workflows/security.yml` | A CI gate: secret scan + dependency audit on every push/PR. |

## Install as a Claude Code plugin (one command)

```shell
/plugin marketplace add REPLACE_ME/xche-ai-app-security-pack
/plugin install ai-app-security@xche
```

This activates three things:
- a **`secure-coding` skill** that auto-applies the security rules whenever Claude Code writes or edits auth / database / API / input / secrets / LLM-MCP code (no command needed — it triggers on the task);
- an **`/ai-app-security:audit`** command for a full manual review of selected code or recent changes;
- an active **secret-blocking hook** before commits. (The hook uses [gitleaks](https://github.com/gitleaks/gitleaks) if installed, and skips silently otherwise.)

> For the strongest, *always-on* coverage, also drop `CLAUDE.md` into `~/.claude/CLAUDE.md` (or `AGENTS.md` into your repo). A skill triggers when the task matches; `CLAUDE.md` is in context on **every** turn. Use both.

## Or use the files directly (any tool, 2 minutes)

1. **Cross-tool rules:** copy `AGENTS.md` into your repo root (Cursor/Codex/Gemini/etc. read it automatically).
2. **Claude Code global rules:** copy `CLAUDE.md`'s contents into `~/.claude/CLAUDE.md`.
3. **Per-project policy:** drop `SECURITY.md` into your repo root for the full reference.
4. **Block secret leaks locally:** install [pre-commit](https://pre-commit.com/), then `pre-commit install`.
5. **Block them in CI:** copy `.github/workflows/security.yml` into your repo.

## Works with

`AGENTS.md` covers the cross-tool agents; `CLAUDE.md` + the plugin cover Claude Code natively; and the **policy, gitleaks hooks, and CI gate are tool-agnostic** — use them with Cursor, Codex, Gemini CLI, Bolt, Lovable, or any AI-assisted (or human) codebase. `AGENTS.md` and `CLAUDE.md` are kept in sync and are each self-contained, so either works dropped in on its own.

> ⚠️ This is a strong baseline, **not** a guarantee. It catches the common classes; business-logic flaws and novel issues still need human review. Pair it with `/security-review` and — for anything handling money, auth, or personal data — a real audit.

## Shipped something fast and want it checked?

If you've built an app with an AI tool and want to know it won't be the next breach headline, I do **security audits + remediation** for AI-built apps.

`→ [ your audit / book-a-call link ]`

## Contributing

Found a gap or a rule worth adding? PRs and issues welcome — this policy improves with real-world findings.

⭐ **If this helped, star the repo** — it helps other AI builders find it before they ship a leak.

## License

MIT — use it, fork it, ship it.
