# Data governance & privacy

| Rule | Enforced by |
|---|---|
| PII columns are tagged (meta `pii: true`, class basic/sensitive) and listed in docs/security/PII-REGISTER.md | review |
| Marts expose PII only to authorised consumers; otherwise hashed/masked/aggregated | tests, review |
| Retention per dataset is implemented (partition expiry / deletion jobs) | review, jobs |
| Dev/CI use synthetic seeds or anonymised samples — never copies of production | guard hook, review |
| Access by role (warehouse grants as code); service accounts least-privilege | IaC review |
| Legal basis (VN Law 91/2025/QH15, Decree 356/2025; GDPR if EU) checked with the PII owner before new personal-data use | kit-appsec |
