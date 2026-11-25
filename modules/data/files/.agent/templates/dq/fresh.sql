-- dimension: fresh (sống) · dataset: {{DATASET}}
-- severity: error
-- why: <e.g. "gold is refreshed by 07:00 every day; a source that stops sending is noticed within a day">
-- owner: <who fixes it>
-- Returns the rows that VIOLATE the rule (0 rows = pass). One read-only SELECT, no trailing semicolon.
-- Date arithmetic differs per engine: Trino/Spark `current_timestamp - INTERVAL '1' DAY`, Postgres `now() - interval '1 day'`,
-- DuckDB `now() - INTERVAL 1 DAY`. Keep one, delete the rest.

-- a) the newest load is older than the SLA
SELECT MAX(<loaded_at_col>) AS last_load
FROM <schema>.<table>
HAVING MAX(<loaded_at_col>) < current_timestamp - INTERVAL '1' DAY

-- b) per source / per unit: which ones went silent
-- SELECT <source_col>, MAX(<loaded_at_col>) AS last_load
-- FROM <schema>.<table>
-- GROUP BY <source_col>
-- HAVING MAX(<loaded_at_col>) < current_timestamp - INTERVAL '2' DAY
