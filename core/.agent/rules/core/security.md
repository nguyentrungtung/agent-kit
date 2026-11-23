# Security (OWASP ASVS / Top 10 baseline)

- Secrets never in code, logs, tests, docs, commits or chat. Names in `.env.example`; values set by humans / secret manager.
- Validate every input at the boundary (type, length, range, format, allow-lists). Encode output for its context.
- Parameterised queries only. No dynamic code execution, no shell with user input, no deserialisation of untrusted data.
- AuthN via the framework's proven mechanism; AuthZ checked server-side on every request (deny by default, object-level checks — no IDOR).
- Passwords: argon2id or bcrypt via the framework. Access tokens are short-lived, signed and rotated; cookies are `HttpOnly; Secure; SameSite`.
- Least privilege for DB users, service accounts, containers (non-root), CI tokens.
- Dependencies: pinned + lockfile committed; audit in CI; no abandoned/unknown packages without an ADR.
- Errors to clients are generic (no stack traces, SQL, paths); details go to logs with a correlation id.
- Security-relevant events are logged (login, permission change, data export) without sensitive values.
- Enforced by: secrets scan (pre-commit + CI), semgrep, trivy, dependency audit, `kit-security` review, `checklists/security.md`.
