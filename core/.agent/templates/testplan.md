---
task: {{ID}}
title: {{TITLE}}
change: {{CHANGE}}
updated: {{DATE}}
---
# Test cases — {{ID}} {{TITLE}}
<!-- Written BEFORE the code (kit-testcases). Every AC has ≥ 1 row; every row is automated or marked manual with a reason.
     Techniques: equivalence partitions, boundary values, decision tables, state transitions, error guessing, security, regression. -->

| ID | AC / scenario | Type | Level | Precondition / data | Steps / input | Expected | Automated in | Status |
|---|---|---|---|---|---|---|---|---|
{{ROWS}}

## Edge & negative cases considered
- Boundaries:
- Invalid input / validation:
- Permission / authorization:
- Not found / conflict / concurrency:
- External failure (timeout, 5xx):

## Run
<!-- Command(s) that run exactly these tests, e.g. .agent/scripts/kit-run test -->
