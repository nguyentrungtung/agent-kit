# Task workflow (every task, every stack)

Every task traces back to an explicit source (requirement, spec/change, issue, or human request). If none is linked, stop and ask.

| # | Step | Output (where) | Gate |
|---|---|---|---|
| 1 | **Understand** — read the task (including `tags`), its linked source/spec (if plugins active), check topic lessons in `.agent/memory/LESSONS.md` (`kit-context --topic <tag>`), relevant rules | Task §1 in your own words | §1 not empty + source linked |
| 2 | **Clarify** — tick every item of the ambiguity checklist below (ticked + "n/a: why" when it does not apply); ask the human ONE batch; never guess a business fact | Task §2 checklist + Q&A table | every checklist item ticked (8 standard dimensions; missing ones only warn), every question answered |
| 3 | **Solution** — check existing code first (code intelligence / grep), approach + rejected alternatives, data/API changes | Task §3; ADR for project-wide choices | §3 not empty |
| 4 | **Tests first** — test cases from every AC (`kit-new testplan`), write them, see them FAIL for the right reason | `docs/qa/TASK-NNN.md` + test code | every AC in the test plan |
| 5 | **Implement** — smallest change that passes; follow `.agent/rules/`; checkpoint each green step | code + `kit-task checkpoint` | `kit-run check` green |
| 6 | **Verify** — all tests pass, review in a fresh context (`kit-review` → `kit-task review "…"`), security (`kit-security`) when relevant, DoD checklist | ticked ACs, review line in Progress log | `kit-task verify` (also run by CI on the PR) |
| 7 | **Document** — update living docs in the same PR (README / active plugin docs such as specs, contracts, architecture); fill Result | Task §7 | §7 not empty + docs check |
| 8 | **Finish** — `kit-task finish` (gates + checks + plugin archive + PR) → human merges; if unexpected issues occurred, add 1 lesson to `.agent/memory/LESSONS.md` (`- YYYY-MM-DD [topic] what went wrong → what to do instead`) | PR | CI green, human approval |

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
Only a human turns it into `CONFIRMED: <answer> (who, date)`; `kit-task verify` blocks while one is open in the task or active plugin docs
(task files from before the 0.11 upgrade keep the old rules).

## Anti-drift guards (what stops an agent from building the wrong thing)
| Guard | Catches | Where |
|---|---|---|
| `kit-trace` | referenced ids that do not exist; module folders not in modules.md | `kit-run check`, CI guard job |
| `kit-task verify` | no source, checklist not walked, unanswered questions, open assumptions, AC without real tests, no code review recorded / open BLOCKER-MAJOR, feature code without living doc change | `kit-task finish`, CI on every task PR |
| arch test (`kit-run arch`) | forbidden dependencies between modules/layers (from `.agent/rules/project/modules.md`) | `kit-run check`, CI |

## Never
- Start coding before steps 1–3 are written down, or write tests after the code "to make coverage".
- Split tasks horizontally into micro-tasks (entity-only, DTO-only); always deliver vertical slices (Size M) using `kit-task checkpoint` for intermediate progress.
- Change behaviour without updating matching living docs/specs in the same PR.
- Cite an id, a file, a function or a library API you have not seen — look it up (code intelligence / grep / docs) or ask.
- Mark your own `ASSUMPTION:` as `CONFIRMED:` — only the human confirms.
- Read old task files / archived records to learn how the system works — read living docs (`docs/README.md` / active specs) instead.
