# Pipelines & operations

| Rule | Enforced by |
|---|---|
| Idempotent: re-running a load for the same interval gives the same result (MERGE on keys / partition overwrite) | tests, review |
| Incremental models declare a unique key and a late-data lookback; full refresh must also work | dbt config, review |
| Backfills are parameterised (date range vars), documented and tested on the ci target — never ad-hoc SQL in production | runbook, review |
| Schedules, dependencies, retries with backoff, timeouts, owners and alerts are declared in code (Airflow/Dagster) | DAG integrity test |
| Schema drift from sources is detected (source freshness + contract) and fails loudly, not silently | dbt source freshness, contracts |
| Cost guardrails: partition pruning, clustering, incremental over full scans, query/job quotas | review, cost dashboard |
| Agents and CI never connect to production; `ci`/`dev` targets with synthetic data only | guard hook (asks on `--target prod`), profiles |
