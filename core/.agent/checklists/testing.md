# Testing checklist — what each kind of change needs (kit-testcases uses this)

| Change | Required tests (in addition to unit tests for new logic) |
|---|---|
| New/changed business rule | unit tests: happy, boundaries, every rule branch (decision table), invalid input |
| New/changed API endpoint | integration test through HTTP: success, validation 400/422, auth 401/403 (+ object-level access), not found 404, conflict 409; OpenAPI updated and linted |
| Database schema / migration | migration up + down on a real DB (container), backfill/data migration test, query plan for new heavy queries |
| Repository / query | integration test on a real DB (Testcontainers / compose), not an in-memory fake |
| External integration | contract or stubbed-server test (timeouts, 5xx, retries, idempotency) |
| UI flow | component tests (Testing Library) + Playwright e2e for the main path + accessibility check (axe) |
| Bug fix | regression test that fails before the fix |
| Security-relevant (auth, input, files, crypto) | negative/abuse tests from the threat model; kit-security review |
| Performance-sensitive path | k6 (or equivalent) smoke/load script with a threshold (p95, error rate) |
| Data pipeline / dbt model | data tests for every contract clause (unique, not_null, relationships, accepted values, recency) |

## Quality bar
- [ ] Tests written first and seen failing; each test name states the behaviour
- [ ] Deterministic: no sleeps, real clock, randomness or network; fixtures are synthetic
- [ ] `kit-run testcov` green (coverage ≥ `coverage_min` where configured); no skipped/disabled tests added
- [ ] Every row of `docs/qa/TASK-NNN.md` is automated (`path::name`) or `manual` with a reason — `kit-task verify` checks it
