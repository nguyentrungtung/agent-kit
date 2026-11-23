# Tasks

<!-- One `## N.` group = one kit task. Tests/contract first in every group. Never run against production. -->

## 1. <!-- e.g. Staging models for source X --> (TASK-NNN)

- [ ] 1.1 Declare sources with freshness and write failing tests for <!-- scenarios --> and verify they fail
- [ ] 1.2 Implement <!-- models --> and verify `dbt build --target ci` passes
- [ ] 1.3 Run `.agent/scripts/kit-run check` and verify it is green
- [ ] 1.4 Update docs/data (contract, lineage, SOURCES) and verify they match

## Workflow follow-up

- `.agent/scripts/kit-task finish` per task (the last one archives this change).
- Backfill in production is run by a human from the documented command.
