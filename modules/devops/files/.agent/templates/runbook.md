---
title: {{TITLE}}
status: draft
owner:
updated: {{DATE}}
---
# Runbook: {{TITLE}}

| | |
|---|---|
| Trigger / alert | |
| Severity | SEV1 / SEV2 / SEV3 |
| Impact on users | |
| Dashboards / logs | |
| Escalation | |

## Prerequisites and access
<!-- Check these before step 1. Names of roles, tools and secrets only — never secret values. -->
| Need | Detail |
|---|---|
| Access / role (and who grants it) | |
| Where to run (host, directory, branch or tag) | |
| Tools and config names | |
| Restore point or backup (needed when a step changes state) | |

## Stop and roll back when
<!-- Fill in BEFORE starting, not during the problem. A runbook that changes nothing: write `n/a — read-only`. -->
| Signal | How to check (command, query, dashboard) | Threshold | Who decides |
|---|---|---|---|
| | | | |

## Diagnose
1.

## Mitigate (fastest safe action first)
1.

## Recover / verify
1.

## Rollback
<!-- Point of no return (the step after which only restore or forward-fix works): -->
1.

## After the incident
- Post-mortem (blameless) with action items as tasks.
