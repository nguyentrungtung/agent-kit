# Authentication & authorization

| Rule | Enforced by |
|---|---|
| Use a proven provider/framework (OIDC/OAuth 2.1, framework auth) — never home-made auth or crypto | ADR, review |
| Password storage uses argon2id or bcrypt via the framework; NIST 800-63B (length ≥ 12, breached-password check, no forced rotation), rate limit + lockout | tests (SEC scenarios) |
| MFA for admin and privileged roles | requirement scenario |
| Sessions: server-side or short-lived signed tokens; rotate on login/privilege change; logout invalidates; cookies `HttpOnly; Secure; SameSite` | tests |
| Authorization on the server for **every** request and **every object** (no IDOR); deny by default | tests per endpoint, review |
| Permissions are named capabilities (`order.approve`), checked in one place (policy/guard), not scattered role string compares | arch test / review |
| Admin/back-office separated (path, network or app) and audited | review |
