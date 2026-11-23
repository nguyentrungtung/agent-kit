# Observability, reliability & recovery

| Rule | Enforced by |
|---|---|
| Structured JSON logs with correlation/trace id; no secrets/PII in logs | logging rule, review |
| Metrics: RED (rate, errors, duration) per endpoint, USE (utilisation, saturation, errors) per resource | dashboard review |
| Traces via OpenTelemetry for cross-service calls | review |
| Each user-facing capability has an SLO (e.g. 99.9% of requests < 500 ms over 28 days) and an error budget | docs/platform/PLATFORM.md |
| Alert on symptoms (SLO burn rate), not causes; every alert links to a runbook; no alert without an owner | runbook template |
| Backups automated, encrypted, retained per policy, and **restore-tested** on a schedule; RTO/RPO written and met | DR checklist |
| Health endpoints: liveness (process ok) separate from readiness (dependencies ok) | review |
| Incidents get a blameless post-mortem with action items as tasks | incident process |
