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

## Change safety (the misses an author's own review usually makes)
- [ ] **Existing users / upgrades:** what happens to data, files, configs or in-flight work created by the previous version?
      (migrations on old rows, old file formats, renamed paths, items already half-done). A rule that is new must not break old records silently.
- [ ] **Every path through a check, not just the happy one:** each branch type / role / state / input kind the code can see;
      what a caller can do to skip it (a gate is only as strong as its weakest entry point).
- [ ] **Parsing edge cases:** escaped delimiters, quoting, empty values, unicode, CRLF, indentation variants, comments/code blocks
      in structured text — use a real parser or test each variant.
- [ ] **Wording vs code:** messages, docs and templates describe exactly what the code enforces (no instruction the check rejects).
- [ ] **Regexes:** anchored, case-sensitivity intended, no accidental match of ordinary words.
- [ ] **A new or changed behaviour has a test that fails without the change** (try reverting the fix once).

## Performance
- [ ] No N+1 queries / unbounded loops / loading whole tables; pagination where lists can grow
- [ ] Indexes for new query patterns; caching has invalidation

## Severity labels for findings
`BLOCKER` must fix · `MAJOR` should fix in this PR · `MINOR` nice to have · `NIT` style only
