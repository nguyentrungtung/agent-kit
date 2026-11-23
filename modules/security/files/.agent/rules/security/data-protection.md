# Data protection & privacy

Legal baseline in Vietnam: **Law on Personal Data Protection No. 91/2025/QH15** (effective 1 Jan 2026) and **Decree 356/2025/ND-CP**
(detailed guidance). EU users → GDPR as well. The kit gives engineering rules, not legal advice — legal/DPO confirms.

| Rule | Enforced by |
|---|---|
| Every personal-data field is listed in `docs/security/PII-REGISTER.md` (category basic/sensitive, purpose, legal basis, retention, storage, access) | review, kit-appsec |
| Collect the minimum; purpose stated; consent captured and stored when consent is the basis | requirement scenarios |
| Sensitive data (health, finance, biometrics, location, …) encrypted at rest at field level or in a separate store; access logged | review, tests |
| No personal data in logs, analytics events, error trackers, URLs or test fixtures (use synthetic data) | log rule, secrets scan, review |
| Retention enforced by code/jobs (delete or anonymise after period) | tests |
| Data-subject rights supported: access/export, correction, deletion — with audit trail | requirement scenarios |
| Lower environments use anonymised or synthetic data only | platform rule |
| Cross-border transfer and third-party processors documented | PII register |
