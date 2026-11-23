# Code review checklist (used by kit-review / code-reviewer sub-agent)

## Correctness
- [ ] Logic matches acceptance criteria; edge cases (null/empty/large/concurrent/timezone/unicode) handled
- [ ] Error handling: no swallowed errors, meaningful messages, correct status codes
- [ ] Resource handling: connections/files/streams closed; timeouts on network calls; retries are idempotent

## Design
- [ ] Respects module boundaries in ARCHITECTURE.md (no forbidden dependencies)
- [ ] Single responsibility; no duplication of existing utilities (search first)
- [ ] No premature abstraction; no dead code; feature flags for risky changes

## Readability
- [ ] Names say what, not how; functions short; comments explain *why*
- [ ] Consistent with surrounding code style

## Tests
- [ ] Tests assert behaviour (not implementation); deterministic (no sleeps, no real network/clock)
- [ ] Failure messages are clear; fixtures minimal

## Performance
- [ ] No N+1 queries / unbounded loops / loading whole tables; pagination where lists can grow
- [ ] Indexes for new query patterns; caching has invalidation

## Severity labels for findings
`BLOCKER` must fix · `MAJOR` should fix in this PR · `MINOR` nice to have · `NIT` style only
