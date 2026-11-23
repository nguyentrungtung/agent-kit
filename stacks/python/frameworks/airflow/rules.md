# Airflow rules

- **Idempotent tasks**: re-running a task for the same data interval produces the same result (MERGE/overwrite a partition keyed by `{{ data_interval_start }}`), never "append again".
- **No top-level work** in DAG files (no DB/API calls, no heavy imports at parse time) — the scheduler parses files constantly.
- Use the TaskFlow API (`@dag`, `@task`) and pass small values via XCom only; large data goes through storage (S3/GCS/warehouse), passing references.
- Templated intervals (`data_interval_start/end`), never `datetime.now()`; `catchup` decided explicitly; `max_active_runs` set for backfill safety.
- Every task: `retries` + `retry_delay` (exponential), `execution_timeout`, an owner; SLAs/alerts on critical DAGs.
- Sensors in `mode="reschedule"` or deferrable operators — never long-poking worker slots.
- Connections and secrets from a secrets backend / env, never in code or Variables in plain text.
- dbt orchestration: one task group per dbt selector (e.g. Cosmos or `dbt build --select tag:daily`), not a single monolithic task.
- Tests: DAG integrity test (all DAGs import, no cycles, required default_args) in CI — see `.agent/stack/python/snippets/test_dag_integrity.py`.
