---
name: kit-catalog
description: Build and keep the data catalog agents and people read BEFORE writing SQL — which table answers which question (and which not to use), entities with their keys and relationships, metric formulas, mandatory filters and gotchas — in docs/data/catalog/, with column meanings kept in the dbt .yml files (one source) and their coverage measured by kit-doc-coverage. Use when a data repo is onboarded, when a question needs a table nobody documented, when numbers disagree because people used different tables or formulas, or after a new source/mart lands.
---
# kit-catalog — know the data before querying it

A wrong table or a wrong formula gives a confident, wrong number. This playbook writes down what the experienced people know, so every
agent (`kit-da`, `kit-data`, a dev) starts from the same map. Inspired by the "data context" practice: entities, ids, metrics, filters, gotchas.

## Where each fact lives (one place each — link, never copy)
| Fact | Single source | Catalog file |
|---|---|---|
| Meaning, type, unit, allowed values of a **column** | dbt `.yml` (`description:` per model / source / column) → `dbt docs` | — (link to the model) |
| **Which table for which question** / which NOT to use and why | `docs/data/catalog/README.md` | the map, read first |
| **Entities**, primary / business / legacy ids, relationships (1-1, 1-n), join paths | `docs/data/catalog/entities.md` (+ mermaid ER) | |
| **Metrics**: plain definition, exact formula with columns, source tables, period convention, caveats | `docs/data/catalog/metrics.md` (or the dbt semantic layer when used) | |
| **Mandatory filters** (test/internal/deleted rows, inactive records) and **gotchas** (time zone, NULL vs '', history vs current state, code lists) | `docs/data/catalog/rules.md` | |
| Code lists (mã danh mục) | a dbt seed or source table, documented in its .yml | linked from rules.md |
| Contracts, SLAs | `docs/data/contracts/` | linked |
| Long business documents (indicator specs, provider exchanges) | where they already are | linked from README.md |

## 1. Harvest what exists (existing repo: before asking anyone)
- `.agent/scripts/kit-doc-coverage <dbt dir> --list` (after `dbt parse`): what is documented, what is not, per layer.
- Read the dbt `.yml` descriptions of the consumer-facing layer (gold / marts) first, then the business docs (`docs/`, indicator specs,
  join notes, code lists) and the SQL of the marts (joins, filters, CASE mappings show the real rules).
- Draft the four catalog files from that. Every statement cites its source (`models/gold/…/mart_x.yml`, `docs/…/NGUON_VA_JOIN.md`).

## 2. Ask the humans only what the sources do not say (one batch, conversational)
- **Entity disambiguation**: "When people say *school* / *student* / *unit*, which table and which id? Are there several kinds?"
- **Identifiers**: business key vs surrogate key vs the provider's id; ids that changed over time.
- **Top questions and metrics**: the 3–5 questions asked most, and the exact formula of each metric (period, numerator, denominator, exclusions).
- **Always filter out**: test data, internal units, deleted / inactive rows, duplicates the source sends.
- **Gotchas**: what new analysts get wrong (wrong table, double counting through a 1-n join, string-typed bronze, time zone, late data).
Unanswered → an `ASSUMPTION:` line in the file and a question in the task; never invent a formula.

## 3. Write the catalog (`docs/data/catalog/`, in `docs_language`)
- `README.md`: question → table/mart, grain, refresh, owner; "do not use X for Y, because…". Short, scannable — agents load it first.
- `entities.md`: one block per entity (definition, primary table, ids, relationships, common filters) + a mermaid `erDiagram`.
- `metrics.md`: one block per metric (definition, formula with real column names, source, period, caveats, a sample query).
- `rules.md`: mandatory filters as ready-to-paste SQL fragments, gotchas with the incident or doc that taught them.
- Missing column descriptions found on the way → add them to the dbt `.yml` (that is the column dictionary), in the project's style.

## 4. Keep it alive
- `kit-da` / `kit-data` read `docs/data/catalog/README.md` before writing SQL; a finding that changes a meaning, a formula or a filter is
  written back here in the same task.
- New mart or source → its catalog line, entity links and column descriptions in the same PR (`kit-doc-coverage --min <n>` can gate it:
  set `doc_coverage_min` in `.agent/project.yaml`).
- Two numbers that disagree → find which table/formula each used, record the right one in `metrics.md`, add a `kit-dq` reconciliation check.

## Done when
README.md answers "which table for my question" for the top questions, every consumer-facing entity and metric has a block with its
source, mandatory filters are in rules.md, and `kit-doc-coverage` shows the consumer-facing layer documented (or the gap is a task).
