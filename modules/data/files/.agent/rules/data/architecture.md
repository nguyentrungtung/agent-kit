# Data architecture

| Rule | Enforced by |
|---|---|
| Design starts from consumers and their questions; every dataset has a named owner and at least one consumer | data contract, review |
| Layers are one-way: raw → staging → intermediate → marts → consumers; marts never read raw/sources directly | dbt_project_evaluator (`kit-run arch`) |
| Raw data is immutable and replayable; transformations are re-runnable from raw | review, backfill test |
| Batch by default; streaming only with a sub-minute consumer need (ADR) | ADR |
| Storage/compute choice (warehouse vs lakehouse) and orchestration tool are ADRs with cost estimates | ADR |
| Lineage is documented (diagram in docs/data, dbt exposures for dashboards/ML) | review, `dbt docs` |
