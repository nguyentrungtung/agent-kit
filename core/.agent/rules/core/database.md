# Database

- Schema changes only through versioned migrations committed with the code; never edit a migration that ran on a shared env.
- Migrations are backward compatible with the previous app version (expand → migrate → contract) for zero-downtime deploys.
- Naming: `snake_case` tables (plural) and columns; `id` PK; FKs `<table_singular>_id`; indexes `ix_<table>_<cols>`, unique `ux_…`.
- Every FK and every column used in frequent WHERE/ORDER BY is indexed; check the query plan for new heavy queries.
- Timestamps `created_at`/`updated_at` in UTC; soft delete only when the domain needs it.
- No N+1: load relations explicitly. Transactions are short and live in the application/service layer.
- Production data is never read or changed by the agent. Seed/fixture data is synthetic.
