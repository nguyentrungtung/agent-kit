# Task workflow (every task, every stack)

Everything traces back to a use case: **UC/US (docs/ba) → OpenSpec change (proposal → specs → design → tasks) → TASK → test → code → living docs.**
If a step has no source to trace to, stop and ask.

| # | Step | Output (where) | Gate |
|---|---|---|---|
| 1 | **Understand** — read the task (including `tags`), its OpenSpec change, linked UC/US/BR, check topic lessons in `.agent/memory/LESSONS.md` (`kit-context --topic <tag>`), current spec (`openspec/specs/`), relevant rules | Task §1 in your own words | §1 not empty |
| 2 | **Clarify** — tick every item of the ambiguity checklist below (n/a allowed); ask the human ONE batch; never guess a business fact | Task §2 checklist + Q&A table; change proposal › Clarifications | 8/8 ticked, every question answered |
| 3 | **Solution** — `codegraph explore/impact` (reuse first), approach + rejected alternatives, data/API changes | Task §3; change `design.md`; ADR for project-wide choices | §3 not empty |
| 4 | **Tests first** — test cases from every AC/scenario (`kit-new testplan`), write them, see them FAIL for the right reason | `docs/qa/TASK-NNN.md` + test code | every AC in the test plan |
| 5 | **Implement** — smallest change that passes; follow `.agent/rules/`; checkpoint each green step | code + `kit-task checkpoint` | `kit-run check` green |
| 6 | **Verify** — all tests pass, review (`kit-review`), security (`kit-security`) when relevant, DoD checklist | ticked ACs | `kit-task verify` (also run by CI on the PR) |
| 7 | **Document** — update living docs in the same PR: OpenSpec specs (via the change), `docs/api`, `docs/architecture`, README; fill Result | Task §7 | §7 not empty, change valid |
| 8 | **Finish** — `kit-task finish` (gates + checks + archive change if last + PR) → human merges; if unexpected issues occurred, add 1 lesson to `.agent/memory/LESSONS.md` (`- YYYY-MM-DD [topic] what went wrong → what to do instead`) | PR | CI green, human approval |

## Ambiguity checklist (step 2)
- Who exactly: actor, role, permission? What if unauthorized?
- Which data: fields, types, required/optional, validation, uniqueness, limits, defaults?
- Edge cases: empty, max size, duplicates, concurrent edits, partial failure, retries/idempotency?
- Errors: what does the user/caller see for each failure? Status codes / messages?
- Numbers: volumes, latency, timeouts, page sizes, retention?
- State: which states can the object be in; what transitions are allowed?
- Integrations: who calls whom, contract owner, what if the other side is down?
- Scope: what is explicitly NOT part of this task?
Unclear and blocking → ask. Unclear but low-risk → `ASSUMPTION: <your best answer>` line and continue.
Only a human turns it into `CONFIRMED: <answer> (who, date)`; `kit-task verify` blocks while one is open in the task or its change.

## Anti-drift guards (what stops an agent from building the wrong thing)
| Guard | Catches | Where |
|---|---|---|
| `kit-trace` | ids (UC/US/BR/FR/NFR/ADR) that are cited but do not exist; stories without UC/AC; module folders not in modules.md | `kit-run check`, CI guard job |
| `kit-task verify` | no source, checklist not walked, unanswered questions, open assumptions, AC without real tests, feature code without spec/doc change | `kit-task finish`, CI on every task PR |
| arch test (`kit-run arch`) | forbidden dependencies between modules/layers (from `.agent/rules/project/modules.md`) | `kit-run check`, CI |
| contract gates | API drift: Spectral, oasdiff breaking changes, stale generated FE types (`kit-run apigen`) | CI |

## Never
- Start coding before steps 1–3 are written down, or write tests after the code "to make coverage".
- Split tasks horizontally into micro-tasks (entity-only, DTO-only); always deliver vertical slices (Size M) using `kit-task checkpoint` for intermediate progress.
- Change behaviour without updating the spec in the same PR.
- Cite an id (UC/US/BR/FR/ADR), a file, a function or a library API you have not seen — look it up (codegraph/grep/docs) or ask.
- Mark your own `ASSUMPTION:` as `CONFIRMED:` — only the human confirms.
- Read old task files / archived changes to learn how the system works — read `openspec/specs/` and `docs/architecture/`.
