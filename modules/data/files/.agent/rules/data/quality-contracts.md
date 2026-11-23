# Data quality & contracts

| Rule | Enforced by |
|---|---|
| Every dataset exposed to consumers has a data contract (`docs/data/contracts/`) and, in dbt, `contract: { enforced: true }` | `kit-run arch` / review |
| Keys: `unique` + `not_null`; foreign keys: `relationships`; enums: `accepted_values`; numbers: ranges | dbt tests (`kit-run test`) |
| Freshness SLA encoded (source freshness + `recency` test) and monitored with an alert | dbt tests, monitoring |
| Volume anomaly bounds for critical facts (row count within expected range) | singular/package tests |
| Contract changes: additive = minor; breaking (rename, type change, removal) = new model version + deprecation window announced to consumers | review, contract versioning |
| Tests are written before the transformation (red → green), one per contract clause | `kit-task verify`, test plan |
