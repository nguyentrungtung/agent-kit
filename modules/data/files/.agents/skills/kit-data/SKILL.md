---
name: kit-data
description: Data engineering design and delivery — analytics architecture (batch vs streaming, ELT, medallion or dbt staging/intermediate/marts layers, warehouse/lakehouse), dimensional models (grain, facts, dimensions, SCD), ingestion and orchestration, data contracts with freshness/quality SLAs, data-quality tests, lineage, backfill and idempotency, PII governance and cost — documented in docs/data/ and specified as OpenSpec changes with the data-flow schema. Use for reporting/analytics/ML data work, pipelines, or when kit-sa hands off data.
---
# kit-data — analytics data engineering

Rules: `.agent/rules/data/` + stack rules (`dbt`, `python` + airflow/pyspark). Living docs: `docs/data/`. Changes: OpenSpec schema **data-flow**
(`.agent/scripts/kit-new change <name> --schema data-flow`). Decisions → ADR. Never touch production data — `ci`/`dev` targets only.

## 0. Know the data
Read `docs/data/catalog/` (kit-catalog) before designing or writing SQL. Every new source, model or mart ships with its column
descriptions in the dbt `.yml` and its line in the catalog — `.agent/scripts/kit-doc-coverage --list` shows what is missing.

## 1. Start from the consumer (not the source)
Read `docs/ba/` and ask ONE batch (or **mp-grilling** rounds): which decisions/dashboards/models consume the data, the business questions,
required **freshness** (e.g. by 07:00 ICT), history depth/backfill window, volumes and growth, accuracy tolerance, PII involved, budget.

## 2. Architecture (ADR) → `docs/data/DATA-ARCHITECTURE.md`
- **Batch vs streaming**: batch (hourly/daily ELT) unless a consumer needs < minutes latency; streaming (Kafka/Debezium CDC + stream processing) only with a real-time use case and ops maturity.
- **Storage**: warehouse (Postgres/BigQuery/Snowflake/ClickHouse) vs lakehouse (Iceberg/Delta on object storage + Spark/Trino). Simplest that fits volume and cost.
  Lakehouse → answer the per-source questions of `.agent/rules/data/lakehouse.md` §1 (full list or changes, measured volume → rebuild or MERGE,
  bronze typing, schema baseline, immutable key, history) in the ADR, and plan maintenance (snapshot expiry, orphan files) from day one.
- **Layers**: raw/bronze (as ingested, immutable) → staging/silver (cleaned, typed, 1:1) → marts/gold (business-ready, contracted). In dbt: `stg_` → `int_` → `fct_`/`dim_`.
- **Ingestion**: managed connector / Airbyte / Debezium / custom jobs; schema-drift policy; late/duplicate data handling.
- **Orchestration**: Airflow (or Dagster) DAGs by domain; dbt run via selectors; SLAs and alerting.
- Lineage diagram (mermaid flowchart: sources → raw → staging → marts → consumers).

## 3. Model → per mart
Grain sentence, keys (natural + surrogate), facts vs dimensions, SCD type per dimension attribute (1 overwrite / 2 history via snapshots),
conformed dimensions shared across marts, time zone and currency conventions.

## 4. Data contract → `docs/data/contracts/<dataset>.md` (`.agent/scripts/kit-new contract "<dataset>"`)
Owner, consumers, schema (names, types, nullability, PK), semantics per column, **SLA** (freshness, completeness, accuracy), PII classes,
change policy (versioning, deprecation window). In dbt: `contract: { enforced: true }` + tests that encode the SLA.

## 5. Quality & tests (written first)
Per dataset: uniqueness + not-null on keys, referential integrity, accepted values/ranges, recency (freshness), volume anomaly bounds,
business-rule singular tests; unit tests for transformation code (PySpark functions, dbt unit tests). They fail before the model exists (red).

## 5b. Hand-off to the Data analyst (`kit-da`)
Before a dataset is delivered (and after any change to it): `kit-da` checks the real data — correct, complete, fresh, clean — with
read-only SQL in `dq/`, reconciles with the source and reports in `docs/data/quality/`. Rules it finds that must always hold come back here as dbt tests.

## 6. Operations
Idempotent loads (MERGE / partition overwrite keyed by interval), parameterised **backfills** (date range vars), reprocessing plan,
monitoring (freshness, row counts, failed tests → alert → runbook), cost per run/day and guardrails (partition pruning, clustering, quotas).
**Releasing a data change** (jobs, models, stored tables, serving, metric logic): write the deploy runbook from
`.agent/checklists/data-deploy.md` — stop/rollback thresholds and a saved baseline are decided before the first step. A human runs it.

## 7. Governance
PII columns tagged and masked/hashed in marts unless the consumer is authorised (update `docs/security/PII-REGISTER.md`); retention per table;
access by role; no production data in dev/CI (synthetic seeds or anonymised samples).

## 8. Deliver via kit-plan / kit-task
One OpenSpec change (data-flow) per dataset or pipeline; one kit task per tasks.md group; `kit-run check` (SQLFluff, dbt parse,
dbt_project_evaluator, dbt build on the ci target). Update `docs/data/` (architecture, contracts, SOURCES) in the same PR.
