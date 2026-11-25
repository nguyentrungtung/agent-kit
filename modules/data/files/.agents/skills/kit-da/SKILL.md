---
name: kit-da
description: Data analyst — profile and verify the data itself with read-only SQL on four dimensions (correct / complete / fresh / clean — đúng, đủ, sống, sạch), reconcile with the source, answer business questions, and turn every finding into a repeatable check (kit-dq) or a dbt test. Use to check a dataset before it is delivered, after a pipeline change, when numbers look wrong, or to reconcile with a data provider.
---
# kit-da — is the data right? (đúng, đủ, sống, sạch)

The Data engineer (`kit-data`) builds pipelines; the Data analyst checks what they produce and what consumers see. Rules:
`.agent/rules/data/`. Checks: `dq/<dataset>/<dimension>-<name>.sql`, run by `.agent/scripts/kit-dq`. Findings: `docs/data/quality/`.

## Safety first (non-negotiable)
- **Read-only.** Every query goes through `kit-dq` (it refuses anything that writes) with `cmd_sql` set to a **read-only** database user.
  Credentials stay in the human's shell environment — never read `.env*`, never put a password in `cmd_sql` or in a file.
- **No personal data out of the database.** Work with counts, sums and distributions. `--samples` only when needed to understand a
  failure, and the rows never go into docs, tasks, commits or chat — describe them ("12 rows with a 10-digit ma_dinh_danh").
- Production is queried only with the human's go-ahead for that environment; prefer the CI/dev target or a sample.

## 1. Question and scope
Which dataset (layer: bronze/silver/gold), which consumer and decision, what "right" means for them (from the data contract in
`docs/data/contracts/` and `docs/ba/`). Unknown rule → ask, do not guess the threshold.

## 2. Profile before judging (one query per question, aggregated)
Row count per day/partition, null and blank rate per column, distinct counts, min/max, top values, length distribution of codes,
duplicates on the declared key. String-typed bronze: profile `TRIM(col) = ''`, numeric-looking and date-looking patterns too.

## 3. Check the four dimensions — `kit-dq new <dataset> <dimension> <name>`, then fill the template
| Dimension | Asks | Typical checks |
|---|---|---|
| **correct — đúng** | Are the values true? | accepted values, ranges, business rules; **reconciliation with the source** (counts and sums per unit/day match the provider's figures); relationships |
| **complete — đủ** | Is anything missing? | required columns filled; every expected day / partition / unit present; row count vs source; no silently dropped columns |
| **fresh — sống** | Is it still alive? | newest load within the SLA; per source: which one went silent; event time vs load time lag |
| **clean — sạch** | Is it tidy? | duplicate keys; malformed ids/phones/dates (regex); stray whitespace, case variants; orphan facts |
Each check returns the violating rows; `-- why:` states the rule, `-- severity: error|warn`. Run: `.agent/scripts/kit-dq run <dataset>`.

## 4. Report → `kit-dq run <dataset> --report` + `docs/data/quality/<date>.md`
Add a short analysis under the generated table: what failed, likely cause (source, ingest, transform), impact on the consumer, owner,
next step. Numbers only, no row values. Discrepancies with an external provider → a question list for them (what we see, period, query).

## 5. Make it stick
- A rule that must always hold → a **dbt test** on the model (hand off to `kit-data`, write it red first) or keep the `kit-dq` check and run
  it in the pipeline/CI against the CI target.
- A rule nobody owns yet → a task (`kit-task new … --type fix`) with the check attached as its acceptance test.
- Wrong numbers found by a consumer → first write the check that reproduces it, then fix, then the check stays.

## Done when
Every agreed rule of the dataset has a check in `dq/` (or a dbt test), `kit-dq run <dataset>` was run on the agreed environment, the
report is in `docs/data/quality/`, and each failure has an owner and a task.
