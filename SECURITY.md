# Claude Code — Comprehensive Security Policy

> **Scope:** house security policy for all code Claude Code writes, edits, or reviews.
> **Deploy as:** `~/.claude/CLAUDE.md` (global), a referenced `SECURITY.md`, or the
> `claude-security-guidance.md` policy file used by the security-guidance plugin.
> **Status:** these are defaults, not suggestions. When a task conflicts with a rule,
> **stop and flag it** — never silently bypass a control to "make it work."
>
> ⚠️ No ruleset is exhaustive. This is the floor. Pair it with the security-guidance
> plugin, `/security-review`, a blocking hook + CI gate, and human review for
> anything touching auth, money, secrets, PII, or medical data.

---

## 0. Operating principles (how to behave)

- Treat all generated and existing code as **unreviewed and untrusted** until it passes this policy.
- **Never weaken, disable, or remove a security control** to fix a bug, pass a test, or hit a deadline. If a control blocks the task, surface it and ask.
- Default to **deny / least privilege / fail closed** everywhere — access, network, permissions, errors.
- **All trust boundaries are server-side.** Client-side validation, hidden fields, disabled buttons, and dropdown limits are UX only — re-enforce on the server.
- When a change touches **authentication, authorization, payments, secrets, file uploads, deserialization, raw SQL, network egress, or LLM/agent tools**, say so explicitly and recommend `/security-review` before commit.
- Prefer **white-box** verification (read the code/query) over blind testing; confirm fixes on **staging**, never probe live production.

---

## 1. Injection & untrusted input (data is never code)

- **SQL/NoSQL:** always parameterized queries / bound parameters / the ORM's safe API. **Never** build queries with string concatenation, f-strings, `.format()`, `%`, or template literals containing user input. No `$where`, `eval`, or operator injection in NoSQL.
- **XSS:** never pass user-controlled data to `dangerouslySetInnerHTML`, `innerHTML`/`outerHTML`, `v-html`, `|safe`, `bypassSecurityTrust*`, `document.write`, or unescaped template output. Rely on framework auto-escaping; encode for the exact output context (HTML/attr/JS/URL/CSS).
- **Command / code injection:** never pass input to a shell, `eval`, `new Function`, `exec`, `child_process` string form, `pickle`/`yaml.load` unsafe, or dynamic `require`/`import`. Use argument arrays and safe parsers.
- **Template injection (SSTI):** never render user input as a template; pass it as data only.
- **Other injection surfaces:** LDAP, XPath, OS path, email headers, log entries, and HTTP response headers must all be encoded/validated.
- **Validation:** validate every input server-side against a schema (Zod / Pydantic / equivalent) using an **allow-list**, with type, length, range, and format constraints. Reject, don't sanitize-and-hope.

## 2. Authentication

- Hash passwords with **argon2id** (preferred) or **bcrypt** — never MD5, SHA-1, SHA-256, or unsalted hashes. Use the library's defaults for work factor; never roll your own.
- Enforce a sane password policy; check against known-breached password lists where feasible.
- Support and encourage **MFA** for sensitive accounts.
- **Sessions:** generate IDs with a CSPRNG; rotate the session ID on login (prevent fixation); invalidate on logout, password change, and timeout. Don't accept session/auth tokens from query strings.
- **Brute force / abuse:** rate-limit and lock/slow auth endpoints (login, reset, OTP, token). Use generic "invalid credentials" messages (no user enumeration).
- **Password reset / email verification:** single-use, expiring, unguessable tokens; never email passwords; don't leak whether an account exists.

## 3. Authorization & access control

- **Object-level (BOLA/IDOR):** every endpoint that reads or modifies an object must verify, server-side, that the object belongs to / is permitted for the authenticated principal. No exceptions for "internal" or "admin" routes.
- **Function-level:** enforce role/permission checks on every privileged action; unlinked admin/debug routes are **not** protected (routes ship in the client bundle).
- **Multi-tenant isolation is mandatory:** scope every query to the caller's tenant/company; cross-tenant access is a critical bug. Assume it's present until proven otherwise.
- **CSRF:** protect all state-changing requests with anti-CSRF tokens and/or `SameSite` cookies; never rely on a single mechanism for cookie-auth flows.
- **Mass assignment / over-posting:** bind request bodies to explicit allow-listed fields; never spread untrusted input straight into DB models or auto-assign role/owner/price fields.
- **Privilege escalation:** validate that users cannot set their own role, tenant, or entitlements via request parameters.

## 4. Secrets & configuration

- **Never** hardcode keys, tokens, passwords, DB URLs, or connection strings. Read from environment / a secrets manager.
- `.env` and `*.env*` in `.gitignore` **before** the first commit. Never commit a real secret, even to a private repo.
- Never expose secrets/PII in: client bundles, URLs/query strings, logs, error responses, analytics, or comments.
- Treat any committed/exposed secret as **compromised** → rotate it; deleting the line is not enough.
- Separate config per environment; secure, least-privilege defaults; no debug mode in production.

## 5. Data protection & cryptography

- **In transit:** TLS everywhere; modern ciphers; HSTS on HTTPS hosts; no mixed content.
- **At rest:** encrypt sensitive fields/PII; use full-disk/DB encryption for sensitive stores.
- Use **vetted crypto libraries** only — never custom crypto. Use authenticated encryption (e.g., AES-GCM/libsodium), a CSPRNG for tokens/IVs/salts, and proper key management/rotation.
- **Cookies:** `HttpOnly` + `Secure` + `SameSite`. Never store secrets or sensitive data in a signed-but-readable session cookie or JWT payload — assume the holder can decode it; keep payloads to non-sensitive identifiers and verify signatures.
- **Data minimization:** collect/retain only what's needed; mask/tokenize where possible.

## 6. API, web & network security

- **Security headers** (proxy or middleware): `Content-Security-Policy` (Report-Only first, then enforce), `Strict-Transport-Security`, `X-Frame-Options: DENY`/`frame-ancestors`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`. Strip stack-revealing headers (e.g. `Server`).
- **CORS:** explicit origin allow-list; never `Access-Control-Allow-Origin: *` on authenticated endpoints; don't reflect arbitrary `Origin`.
- **Rate limiting & quotas** on all public/expensive endpoints; enforce request size/time limits to resist DoS.
- **SSRF:** never let user input control a server-side request target. Allow-list destinations; block private/link-local ranges (`127.0.0.0/8`, `10/8`, `172.16/12`, `192.168/16`, `169.254.169.254`); disable unneeded redirects/protocols. (AI-generated "fetch this URL" features are a top SSRF source.)
- **Open redirect:** validate redirect targets against an allow-list; no user-supplied absolute URLs.
- **File uploads:** validate type by content (not just extension), cap size, store outside the web root with generated names, scan where possible, never execute uploaded content.
- **Path traversal:** canonicalize and confine file paths to an intended base directory; reject `..`.

## 7. Dependencies & supply chain

- **Verify every new package exists** on the official registry before adding it (guard against hallucinated / slopsquatted names). Prefer well-maintained, widely-used packages.
- Pin versions and commit lockfiles; keep the dependency set minimal.
- Run audits (`npm audit` / `pip-audit` / `osv-scanner`) and report/fix criticals; be wary of risky `postinstall` scripts.
- Don't add a dependency for something the standard library already does safely.

## 8. Cloud, infrastructure & containers

- **Database access control:** enable **Row-Level Security**/equivalent; never ship a database publicly readable/writable (the Moltbook/Quittr breach class). Verify default permissions are deny.
- **IAM least privilege:** no wildcard roles; the app's DB/cloud account gets only what it needs (no `DROP`, no admin).
- **Storage:** no public buckets/blobs for private data; verify ACLs explicitly.
- **Network:** default-deny security groups/firewalls; minimal exposed ports; no management ports open to the internet.
- **Containers:** run as **non-root**; read-only filesystem where possible; no `--privileged`; pin base images; no secrets baked into images.
- **CI/CD:** secrets via the platform's secret store, not in pipeline files; restrict who/what can deploy; require review before scanning untrusted PRs.

## 9. Errors, logging, monitoring

- Return **generic** error messages to clients; never leak stack traces, SQL, file paths, versions, or internal hostnames.
- Log security-relevant events (auth, access-control failures, privilege changes) with enough context to investigate — but **never** log secrets, tokens, full card/PII, or session contents.
- Provide audit trails for sensitive actions; alert on anomalies (repeated auth failures, access-control denials).

## 10. LLM / AI / MCP security (OWASP LLM Top 10)

> Critical for this stack: MCP servers, internal models, and **medical/patient data**.

- **Treat all model output as untrusted input.** Never directly execute, eval, render (XSS!), or pass it to a shell/DB/file system without validation and encoding.
- **Prompt injection:** assume any external content (web pages, documents, RAG sources, tool results, user files) may carry adversarial instructions. Don't let retrieved content override system instructions or trigger tool calls; isolate untrusted content and require explicit user intent for actions.
- **MCP server hygiene:** never install MCP servers from public marketplaces without review; **sandbox** each in a container with a read-only filesystem and an outbound network allow-list; disable STDIO servers you don't need; **allow-list commands by absolute path** — no relative paths or env wrappers (the MCP command-injection CVE class).
- **Excessive agency:** give agents/tools least privilege; require **human-in-the-loop** confirmation for high-impact actions (delete, pay, email, modify permissions, write to prod).
- **Sensitive data to models:** never send secrets, credentials, or unminimized PII/medical records into prompts or to third-party model APIs. Prefer local/self-hosted models for regulated data; log and access-control all prompt/response handling.
- **Output handling:** validate/constrain model output to expected schemas; encode before display; rate-limit and cap token/cost to resist abuse and denial-of-wallet.
- **Medical/regulated data:** encryption at rest + in transit, strict access control, full audit logging, data minimization. Flag for **formal compliance review** (GDPR / local medical-data law / EU AI Act high-risk obligations) — code rules are not legal sufficiency.

## 11. Frontend-specific

- No secrets or privileged logic in client bundles (assume fully visible).
- DOM XSS: avoid `innerHTML`/`document.write`/unsafe sinks; use textContent and framework binding.
- `postMessage`: always check `origin` and validate message shape.
- Subresource Integrity (SRI) for third-party scripts; minimize external script sources (tightens CSP).
- Clickjacking: `frame-ancestors`/`X-Frame-Options`.

## 12. Secure-SDLC process rules (for Claude Code specifically)

- For any new feature, briefly **threat-model** it: what's the input, who's authorized, what's the worst case — before writing code.
- When editing existing code, **preserve existing security controls**; call out if a change reduces a control.
- Don't auto-apply security "fixes" to production code without diff review; work on a branch.
- Run `/security-review` on security-sensitive diffs; restrict automated review to **trusted repos/contributors** (PR-content prompt-injection risk).
- Prefer the boring, safe, well-trodden library/pattern over the clever one. "It runs" ≠ "it's safe."

---

### Deployment notes
- **Dilution caveat:** a very long policy can get diluted in context. Two good patterns: (a) keep this full file as `SECURITY.md` and put a short pointer + the top ~15 rules in `CLAUDE.md`; or (b) load it as the security-guidance plugin's policy file, which is purpose-built for a policy this size.
- **Enforcement:** rules here are advisory. For hard gates (block secret commits, block edits to auth/prod files), add a `PreToolUse` hook + a CI security gate.
