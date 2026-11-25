-- dimension: complete (đủ) · dataset: {{DATASET}}
-- severity: error
-- why: <e.g. "every school reported for every day of the last 30 days; required columns are filled">
-- owner: <who fixes it>
-- Returns the rows that VIOLATE the rule (0 rows = pass). One read-only SELECT, no trailing semicolon. Pick ONE pattern, delete the rest.

-- a) required columns not null / not blank (string-typed bronze: blank counts as missing)
SELECT <key_col>
FROM <schema>.<table>
WHERE <required_col> IS NULL OR TRIM(<required_col>) = ''

-- b) missing days / partitions (needs a calendar or a list of expected keys)
-- SELECT c.d AS missing_day
-- FROM <calendar_table> c
-- LEFT JOIN (SELECT DISTINCT <date_col> AS d FROM <schema>.<table>) t ON t.d = c.d
-- WHERE c.d BETWEEN <from_date> AND <to_date> AND t.d IS NULL

-- c) row count vs the source (one row back when they differ)
-- SELECT t.n AS target_rows, s.n AS source_rows
-- FROM (SELECT COUNT(*) AS n FROM <target_table>) t CROSS JOIN (SELECT COUNT(*) AS n FROM <source_table>) s
-- WHERE t.n <> s.n
