# Security rules (global) — Claude Code

> Drop these into `~/.claude/CLAUDE.md` so every project inherits them.
> Cross-tool twin (Codex/Cursor/Gemini/etc.): `AGENTS.md` (same rules).
> Full policy with rationale: `SECURITY.md`.
> For changes touching auth, payments, secrets, or LLM tools, run `/security-review`.
> These are defaults — if a task conflicts with a rule, stop and flag it; never
> bypass a control to "make it work."

- **Never hardcode secrets.** Read keys/tokens/DB URLs from env vars. Ensure `.env`/`*.env*` is gitignored before the first commit. Never put secrets/PII in client code, logs, URLs, or error messages.
- **SQL: always parameterized / ORM.** Never build queries with string concatenation, f-strings, `.format()`, `%`, or template literals containing user input.
- **XSS: never** feed user input to `dangerouslySetInnerHTML`, `innerHTML`, `v-html`, `|safe`, or `document.write`. Rely on framework escaping; encode output for its context.
- **No command injection:** never pass input to a shell, `eval`, `new Function`, or unsafe deserialization (`pickle`, unsafe `yaml.load`).
- **Validate every input server-side** against a schema (Zod/Pydantic), allow-list not block-list. Client-side checks are UX only.
- **Access control:** every endpoint that reads/writes an object must verify ownership/permission server-side. No exceptions for "internal" or unlinked admin routes.
- **Multi-tenant:** scope every query to the caller's tenant. Cross-tenant access (IDOR/BOLA) is a critical bug — assume it's there until proven otherwise.
- **Mass assignment:** bind request bodies to explicit allow-listed fields; never let users set their own role/owner/price/tenant.
- **Passwords:** hash with argon2id or bcrypt — never MD5/SHA-1/unsalted. Rate-limit auth endpoints; generic "invalid credentials" messages.
- **Sessions/cookies:** `HttpOnly` + `Secure` + `SameSite`. Never store secrets/sensitive data in a readable signed cookie or JWT payload.
- **Security headers:** set CSP (Report-Only first), HSTS, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`. No `Access-Control-Allow-Origin: *` on authenticated endpoints.
- **SSRF:** never let user input control a server-side request target; allow-list destinations; block private/link-local ranges incl. `169.254.169.254`.
- **File uploads:** validate by content type, cap size, store outside web root with generated names, never execute.
- **Dependencies:** verify a package actually exists before adding it (no hallucinated/slopsquatted names); pin versions; run the audit tool; keep deps minimal.
- **LLM/MCP:** treat model + tool output as untrusted (encode before render/execute); sandbox MCP servers, allow-list commands by absolute path; require human confirmation for high-impact actions; never send secrets or unminimized PII to models.
- **Errors:** return generic messages to clients; never leak stack traces, SQL, or internal paths. Log security events but never secrets/PII.
- **Process:** for changes touching auth, payments, secrets, or LLM tools, say so and recommend `/security-review`. Never weaken an existing control to pass a test. Confirm fixes on staging, not prod.
