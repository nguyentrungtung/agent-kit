-- dimension: clean (sạch) · dataset: {{DATASET}}
-- severity: error
-- why: <e.g. "one row per (ma_truong, ngay); ma_dinh_danh is 12 digits; every fact row has its dimension">
-- owner: <who fixes it>
-- Returns the rows that VIOLATE the rule (0 rows = pass). One read-only SELECT, no trailing semicolon. Pick ONE pattern, delete the rest.

-- a) duplicate keys
SELECT <key_col_1>, <key_col_2>, COUNT(*) AS copies
FROM <schema>.<table>
GROUP BY <key_col_1>, <key_col_2>
HAVING COUNT(*) > 1

-- b) malformed values (regexp_like: Trino/Spark/DuckDB; Postgres: <col> !~ '<regex>')
-- SELECT <key_col>, <col> FROM <schema>.<table> WHERE NOT regexp_like(<col>, '^[0-9]{12}$')

-- c) stray whitespace / case variants of the same code
-- SELECT <code_col> FROM <schema>.<table> WHERE <code_col> <> TRIM(<code_col>) OR <code_col> <> UPPER(<code_col>)

-- d) grain on raw: within one pull a key has at most ONE distinct content hash (otherwise dedup silently drops a real record)
-- SELECT <key_col>, <pull_date_col>, COUNT(DISTINCT <row_hash_col>) AS versions FROM <raw_table>
-- GROUP BY <key_col>, <pull_date_col> HAVING COUNT(DISTINCT <row_hash_col>) > 1

-- e) orphans: fact rows without their dimension
-- SELECT f.<fk_col> FROM <fact_table> f LEFT JOIN <dim_table> d ON d.<pk_col> = f.<fk_col> WHERE d.<pk_col> IS NULL
