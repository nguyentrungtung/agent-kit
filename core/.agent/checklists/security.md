# Security checklist (used by kit-security / security-reviewer sub-agent) — based on OWASP Top 10 / ASVS

## Secrets & config
- [ ] No secrets in code, tests, fixtures, logs, docs, commit history (`kit-secrets-scan --all`)
- [ ] Config only via env; `.env.example` lists names with fake values

## Input & output
- [ ] All external input validated (type, length, range, format) at the boundary
- [ ] Queries parameterized (no string-built SQL/NoSQL/LDAP/shell); no `eval`/dynamic code
- [ ] Output encoded for its context (HTML, JSON, headers, logs); file paths canonicalized (no path traversal)
- [ ] Uploads: size/type limits, stored outside web root, scanned if needed

## AuthN / AuthZ
- [ ] Every endpoint/action has an explicit authorization check (deny by default)
- [ ] Object-level access checked (user can only touch own resources — IDOR)
- [ ] Passwords hashed with a slow KDF (bcrypt/argon2); tokens expire; sessions rotated on login

## Data protection
- [ ] PII / sensitive data identified; minimized; encrypted at rest/in transit where required
- [ ] Logs contain no passwords, tokens, full card numbers, full PII
- [ ] Error responses leak no stack traces / internals

## Dependencies & supply chain
- [ ] New dependency is maintained, licensed OK, pinned; `kit-run audit` has no HIGH/CRITICAL
- [ ] No `curl | sh`, no unverified binaries

## Web/API specifics (if applicable)
- [ ] CSRF protection for cookie auth; CORS restricted; security headers set
- [ ] Rate limiting / brute-force protection on auth and expensive endpoints
- [ ] SSRF: outbound URLs from user input are allow-listed

Findings format: `[SEVERITY] file:line — issue — fix`  (CRITICAL / HIGH / MEDIUM / LOW)
