---
dataset: {{TITLE}}
version: 1
status: draft               # draft | active | deprecated
owner:
consumers: []
updated: {{DATE}}
---
# Data contract: {{TITLE}}

## Purpose & grain
<!-- What it is for; "one row per …". -->

## Schema
| Column | Type | Nullable | Key | Meaning | PII class |
|---|---|---|---|---|---|

## SLA
| Dimension | Promise | Checked by |
|---|---|---|
| Freshness | updated by 07:00 Asia/Ho_Chi_Minh daily | dbt source freshness + recency test |
| Completeness | row count within ±20% of 7-day average | volume test |
| Uniqueness | `<key>` unique | dbt `unique` |
| Validity | enums / ranges as listed | dbt `accepted_values` / `accepted_range` |

## Change policy
Additive changes: minor, announced. Breaking changes: new model version, both versions served for ≥ 30 days, consumers notified.

## Lineage
<!-- upstream sources/models → this dataset → consumers -->
