# dbt / analytics SQL rules (community standards)

Sources: dbt Labs "How we structure our dbt projects" + style guide, dbt_project_evaluator rules, Kimball dimensional modelling.

| Rule | Enforced by |
|---|---|
| SQL style: lowercase keywords/identifiers, explicit aliases, trailing commas, CTEs not subqueries, ≤ 120 chars | SQLFluff (`kit-run format_check`, `lint`) |
| Project parses; refs/sources resolve | `dbt parse` (`kit-run typecheck`) |
| DAG best practices: no direct joins to sources from marts, no rejoining upstream, staging 1:1 with sources, fan-out limits, documented & tested models | dbt_project_evaluator (`kit-run arch`) |
| Every model builds and every test passes on the CI target | `dbt build --target ci` (`kit-run test`) |

## Layers & naming (dbt convention)
| Layer | Folder | Name | Materialization | Rules |
|---|---|---|---|---|
| Sources | `models/staging/<source>/_<source>__sources.yml` | — | — | declare every raw table with `loaded_at_field` + freshness |
| Staging | `models/staging/<source>/` | `stg_<source>__<entity>` | view | 1:1 with a source table; rename, cast, light cleaning only; no joins |
| Intermediate | `models/intermediate/<domain>/` | `int_<entity>_<verb>` | ephemeral/view | joins and business logic building blocks; not exposed |
| Marts | `models/marts/<domain>/` | `fct_<process>` / `dim_<entity>` | table/incremental | consumer-facing, **contract enforced**, documented grain |
| Snapshots | `snapshots/` | `snp_<entity>` | snapshot | SCD type 2 history of mutable sources |

## Modelling
- State the **grain** of every fact in its description ("one row per order line"); every mart has a primary key tested `unique` + `not_null`.
- Star schema for analytics: facts (measures, foreign keys, event time) + conformed dimensions; surrogate keys via `dbt_utils.generate_surrogate_key`.
- Only `ref()` and `source()` — never hard-coded database/schema names. Timestamps in UTC; currency columns carry the unit in the name (`amount_vnd`).

## Incremental & idempotency
- Incremental models declare `unique_key` and handle late-arriving data with a lookback window; `on_schema_change: fail` on contracted marts.
- Every model can be fully rebuilt (`--full-refresh`) and re-run without duplicates. Backfills are parameterised (vars), never manual SQL.

## Tests & contracts
- Generic tests on keys (`unique`, `not_null`, `relationships`), enums (`accepted_values`), ranges, recency; singular tests for business rules.
- Marts consumed outside the team have `contract: { enforced: true }` with column data types; breaking changes need a new model version (`versions:`).
- Data tests are written **before** the model logic (red: the test fails or the model is empty) — same TDD loop as code.

## Docs
- Every model and column consumed downstream has a description; `dbt docs generate` in CI; exposures for dashboards/ML that depend on marts.
