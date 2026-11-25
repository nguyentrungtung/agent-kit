# Metrics

> One block per metric. A formula names real columns. Unknown part → `ASSUMPTION:` + a question, never a guess.

## TODO: <Metric name>
- **Definition**: plain language.
- **Formula**: `SUM(<table>.<col>) / COUNT(DISTINCT <table>.<col>)` — numerator, denominator, exclusions.
- **Source table(s)**: `<mart>` ([yml](…)).
- **Period**: calendar month / school year / as of date …; time zone.
- **Caveats**: late data, revisions by the provider, units that do not report.
- **Sample query**:
```sql
SELECT …
```
- **Source**: `<indicator spec / doc>`
