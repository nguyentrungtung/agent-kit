# Lakehouse — decisions to make per source, and failure modes seen in production

Read when the storage is a lakehouse (Iceberg / Delta on object storage, Spark / Trino). Distilled from a production lakehouse
(Iceberg + REST catalog + MinIO + Spark Thrift + dbt-spark + Trino + Postgres serving). **The project's answers go to an ADR and
`.agent/rules/project/`** — this file asks the questions and says what went wrong when they were not asked. It holds no tuning values:
those depend on versions and hardware and belong to the project, measured.

## 1. Ask on day one, for EVERY source (each answer → one line in the source's ADR / model comment)
| Question | Why it matters | Default |
|---|---|---|
| Does the source return the **full list** each time, or only **changes**? | Full list + incremental MERGE keeps rows the source stopped sending (units dissolved, indicators dropped) forever | Full list → rebuild the silver table and flag `is_active` (row present in the latest pull of its scope); gold reads `WHERE is_active` |
| How big is it, **measured** (rows, GB, rebuild minutes)? | One strategy for all sources either wastes hours or bloats storage | Small → rebuild the whole table each run (simplest, no MERGE). Large → incremental MERGE on the key, writing only new/changed rows |
| How is bronze typed? | A source that changes `5` to `"5"` or `5.0` breaks typed ingestion or casts wrongly | **Bronze = raw, all STRING** (schema-on-read), only the load timestamp typed; types are silver's job (`TRY_CAST`). Decide in an ADR; then every new source follows it |
| Where is the schema baseline? | A contract file next to the catalog = two truths that drift | The catalog's current table schema. Ingest compares each batch to it: new column → load + alert (cap it), missing required column → fail before commit |
| What is the **immutable business key**? | It decides update vs duplicate vs silent loss (§2) | Written in the model with one line of why |
| Is history of states needed (e.g. a case going through statuses)? | Silver keeps the latest state only | History from bronze (one snapshot per pull) or a dedicated history model (`valid_from/valid_to/is_current`) |
| Does anything share an engine with other sources? | One slow source starves the others | One pipeline per source end to end; every job has a time budget; no job reads two domains |

## 2. Keys, dedup, MERGE
- Key = identifiers the source assigns and never changes (+ the reporting period). **Never** status, names, labels, free text or
  measures in the key — a changed status then gives a new key: MERGE inserts instead of updating and gold counts the entity twice.
- Three hashes, three jobs — do not mix them: row hash (bronze, skip identical payloads), key hash (`_pk`, identity for MERGE), content
  hash (MERGE only rows that changed).
- Normalise keys before dedup: `NULLIF(TRIM(x), '')`; integers that may arrive as `N.0` → cast through DOUBLE; a NULL key goes to
  quarantine (all NULL keys would merge into one row).
- Tests on every silver model: `unique(_pk)`, `not_null` on key columns, and a **grain test on bronze**: within one pull a key has at most one
  distinct row hash (otherwise dedup silently drops a real record — `kit-dq` template `clean`).
- "Latest" = a business update timestamp when the source has one; load time otherwise. A backfill of old data sorted by load time
  overwrites newer states. Tie-breakers must carry order (step number), not a hash.
- Changing the key columns changes every `_pk` → full refresh, compare row counts before/after, never store `_pk` outside the lakehouse.

## 3. Storage growth (it grew 15× before anyone looked)
- Copy-on-write MERGE rewrites whole files; a silver that re-emits every "latest" row each run doubles per snapshot. Write only changed rows.
- Snapshot expiry must also **delete the files** only the expired snapshots used (some libraries only drop metadata); orphan-file cleanup
  with a safety age. The maintenance schedule must be **on in production** and checked — a STOPPED schedule is the same as none.
- Object-store **versioning** only where a backup is needed (raw); derived buckets: suspended + lifecycle for non-current versions —
  otherwise deletes free nothing. Measure `size with versions` vs `size`.
- Drop tables **through the catalog** with purge; deleting files on the object store leaves the table pointing at nothing.
- A "dry-run" flag needs a test proving the state did not change — one expiry dry-run still removed snapshots.
- Never age-out raw partitions: raw is the only copy of what was pulled; silver/gold are rebuilt from it (full refresh), never hand-patched.

## 4. Engines
- Long-running JVM services (Spark master/worker/Thrift): the JVM is the container's main process with an init (`tini`) and a restart
  policy. `start-*.sh && tail -f` hides an OOM-killed JVM behind a container that stays "Up".
- A Thrift server shared by dbt: one session per JDBC connection that is never closed leaks catalogs and threads until OOM — use a single
  shared session (then clients must not `SET` their own values) and measure sessions after every upgrade. Never "fix" a leak with RAM.
- Container memory limit = heap + off-heap (metaspace, direct, threads) + headroom — never equal to the heap; standalone Spark does not
  count executor overhead.
- Master restarts lose running applications unless recovery mode is on.
- Catalog metadata may be cached for ~30 s: a write-then-read test must wait.
- Python readers of large tables stream in bounded batches; measure peak RAM on real data before writing the runbook.

## 5. Gold and serving
- Aggregate measures to the **narrowest key** before joining or rolling up; joining an aggregate to a wider table multiplies it.
- One base mart at the finest grain; other marts roll up from it, so every level agrees and a new indicator is one change.
- Map columns from the **source's data dictionary**, not from the column name; a strange-looking number is checked against bronze before
  it is "fixed".
- Missing ≠ zero: no data → NULL; a ratio's denominator counts only units that reported; zero denominator → NULL; sum counts across groups, never average ratios.
- Business counting rules agreed with the owner become tests with severity error (the pipeline stops, serving keeps the old data).
- Serving: replace atomically (stage, then delete + insert in one transaction); tables with periods replace only the periods synced;
  an empty stage is refused. A new gold column ships with the serving DDL change, or it silently never reaches consumers.

## 6. Operating changes
- Migrations of raw data: in place, with a backup, a hash-by-hash verify, rollback and a guarded backup drop — rehearsed on a local copy.
- Runbooks: every command tried once, a "go back" section, kept where `git pull` brings it.
- One-off scripts are deleted once run everywhere (re-running one later can corrupt data).
- After a design change: grep every doc for the old wording and overwrite it; run dead-code checks.
