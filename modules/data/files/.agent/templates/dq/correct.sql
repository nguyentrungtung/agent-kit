-- dimension: correct (đúng) · dataset: {{DATASET}}
-- severity: error
-- why: <the rule in one sentence, e.g. "so_hoc_sinh is never negative and matches the source total per district">
-- owner: <who fixes it>
-- Returns the rows that VIOLATE the rule (0 rows = pass). One read-only SELECT, no trailing semicolon. Pick ONE pattern, delete the rest.

-- a) range / accepted values
SELECT <key_col>, <value_col>
FROM <schema>.<table>
WHERE <value_col> < 0
   OR <status_col> NOT IN ('<allowed_1>', '<allowed_2>')

-- b) reconciliation with the source (đối soát): totals per group must match
-- SELECT t.<group_col>, t.total AS target_total, s.total AS source_total
-- FROM (SELECT <group_col>, SUM(<measure>) AS total FROM <target_table> GROUP BY <group_col>) t
-- FULL OUTER JOIN (SELECT <group_col>, SUM(<measure>) AS total FROM <source_table> GROUP BY <group_col>) s ON t.<group_col> = s.<group_col>
-- WHERE COALESCE(t.total, -1) <> COALESCE(s.total, -1)
