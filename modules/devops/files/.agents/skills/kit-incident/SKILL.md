---
name: kit-incident
description: Handle a production incident — classify severity, stabilise first (rollback / feature flag / scale), communicate on a fixed cadence, collect a timeline, then write a blameless post-mortem with action items turned into tasks. Use when something is broken in production or an SLO alert fires. The agent advises and prepares; humans execute production actions.
---
# kit-incident — incident response (humans act on production; the agent assists)

## 1. Triage (first 5 minutes)
| Severity | Meaning | Response |
|---|---|---|
| SEV1 | Outage or data loss/leak for many users, security breach | all hands, updates every 15–30 min, leadership informed |
| SEV2 | Major feature broken / severe degradation, workaround exists | on-call + owner, updates every hour |
| SEV3 | Minor impact, single customer, cosmetic | normal task, next business day |
Open `docs/platform/incidents/<date>-<slug>.md` with `.agent/scripts/kit-new postmortem "<title>"` and start the **timeline** (UTC timestamps).

## 2. Stabilise before diagnosing
Fastest safe mitigation first: roll back to the previous image/tag, disable the feature flag, scale out, fail over, block abusive traffic.
Use the runbook linked from the alert (`docs/platform/runbooks/`). The agent proposes commands; a human runs them (guard hooks ask/block).
Security incident (leak, intrusion): preserve evidence, rotate exposed secrets, involve the security owner; personal-data breaches have legal
notification duties (VN Law 91/2025/QH15 / Decree 356/2025 — the DPO decides).

## 3. Communicate
Status update template: *what is affected · since when · current action · next update at*. One channel, one incident lead.

## 4. Diagnose & fix
After stabilising: reproduce with **mp-diagnosing-bugs**, fix through a normal `hotfix` kit task (`kit-task new --type hotfix` → branch from main),
regression test first.

## 5. Post-mortem (within 5 working days, blameless)
Complete the incident file: impact (users, duration, money/data), timeline, root cause(s) with 5 whys, what went well/badly,
**action items** → `kit-task new … --type chore|fix` each with an owner; detection gaps → new alerts/SLOs; runbook updates.
