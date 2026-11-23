---
name: kit-datamodel
description: Design the application (OLTP) data model — entities and aggregates from the domain/glossary, relationships (1-1, 1-n, n-n with join tables), normalisation (3NF) and when to denormalise, keys and the ID strategy (BIGINT identity vs UUIDv7 vs public id), constraints and indexes, multitenancy, audit/soft delete, time and money types, migration plan (expand → migrate → contract) — documented in docs/architecture/data-model.md with an ERD and ADRs. Use before implementing persistence for a new module or when changing schema. Analytics models belong to kit-data.
---
# kit-datamodel — application data model

Inputs: `GLOSSARY.md`, use cases/stories (`docs/ba/`), module boundaries (`docs/architecture/SOLUTION.md`), rules `.agent/rules/core/database.md`.
Output: `docs/architecture/data-model.md` (living) + ADRs + migrations via kit-task. Terms come from the glossary (mp-domain-modeling).

## 1. Entities & aggregates
- One entity per domain noun with identity and lifecycle; value objects (money, address, email) as columns/embedded types, not tables, unless shared.
- **Aggregate** = consistency boundary (e.g. Order + OrderLines): one transaction changes one aggregate; other aggregates referenced by id.
- **Ownership**: each table belongs to exactly one module; other modules read it through that module's API/events — no cross-module joins
  in a modular monolith (a reporting read model or analytics pipeline is the exception).

## 2. Relationships
| Kind | Implement as | Notes |
|---|---|---|
| 1-1 | FK with UNIQUE on the dependent side, or same table if always loaded together | split only for optional/large/sensitive parts |
| 1-n | FK on the "many" side + index on it | ON DELETE: RESTRICT by default; CASCADE only inside one aggregate |
| n-n | join table `<a>_<b>` with composite PK (or own id when it carries attributes) | attributes on the link (role, quantity) → it is an entity |
| Hierarchy | adjacency list (`parent_id`) + recursive CTE; closure table if deep reads dominate | |
| Polymorphic | separate FKs or one table per type; avoid `(type, id)` pairs without FK | integrity first |

## 3. Normalise, then denormalise on evidence
3NF by default (each fact once). Denormalise only for a measured read path (cached totals, snapshot of price at order time — which is
*data*, not duplication). Document every denormalisation with how it stays consistent (trigger, event, job).

## 4. Keys & ID strategy (decide once per project → ADR "ID strategy")
| Situation | Primary key | Why |
|---|---|---|
| Single DB, internal records, high write volume, ids never exposed | `BIGINT GENERATED ALWAYS AS IDENTITY` | smallest, fastest index, ordered |
| Ids appear in URLs/APIs, generated client-side/offline, merged from several sources, distributed writes | **UUIDv7** (time-ordered) | not guessable, no coordination; v7 keeps B-tree inserts ordered (v4 fragments indexes) |
| Both concerns | internal `BIGINT` PK + `public_id UUIDv7 UNIQUE` exposed externally | joins stay small, external ids opaque |
| Small fixed lookup tables | natural `code` (e.g. `VND`, `paid`) or `SMALLINT` | readable, stable |
Never expose sequential ids where enumeration is a risk (IDOR). Natural keys (email, tax code) are UNIQUE constraints, not PKs.

## 5. Constraints & indexes
NOT NULL by default; CHECK for enums/ranges; UNIQUE for business uniqueness (partial unique for soft delete); FK on every reference.
Index every FK and every filter/sort column of a frequent query; composite index order = equality columns first, then range/sort.
Verify heavy queries with EXPLAIN before merging.

## 6. Cross-cutting columns
- `created_at`, `updated_at` (UTC, `timestamptz`); `created_by` when audit matters; optimistic locking `version` for concurrent edits.
- Soft delete (`deleted_at`) only when the domain needs restore/audit; otherwise delete + audit log. Personal data deletion must really delete/anonymise.
- Money: `NUMERIC(18,2)` (or integer minor units) + currency code; never float. Time zones: store UTC, convert at the edge.
- Multitenancy (ADR): database-per-tenant (strong isolation) · schema-per-tenant · shared tables with `tenant_id` + row-level security. Every query is tenant-scoped.

## 7. Migrations
Versioned migrations only (Flyway, Laravel, Doctrine, Alembic, Prisma, EF Core). Zero-downtime: **expand** (add nullable/new) → migrate data (batched job)
→ switch code → **contract** (drop old) in a later release. Every migration has a tested down path or a documented forward fix.

## 8. Document
`docs/architecture/data-model.md`: ERD (mermaid erDiagram) per module, data dictionary (column, type, null, constraint, meaning, PII), ownership table,
ID strategy and multitenancy ADR links. PII columns → `docs/security/PII-REGISTER.md`.
