---
name: kit-task
description: Execute ONE task end-to-end with the agent-kit workflow — understand, clarify, design the solution, write tests first, implement in checkpointed steps, verify, document, finish with a PR (gitflow, restore points, active plugin gates). Use whenever writing or changing code.
---
# kit-task — implement one task the same way every time

Rules: `.agent/rules/core/workflow.md` (the 8 steps + ambiguity checklist). Every step writes into the task file.

## 0. Preconditions
- A task file exists (`.agent/scripts/kit-task new "<title>"` / `kit-new task`). No task → `kit-plan` or ask.
- `depends_on` tasks are done. Check any linked change / spec from active plugins in `AGENTS.md §1b`.

## 1. Start
```bash
.agent/scripts/kit-task start TASK-NNN            # branch <type>/TASK-NNN-slug + restore point kit/TASK-NNN/base
.agent/scripts/kit-task start TASK-NNN --worktree # parallel: ../<repo>-TASK-NNN, open a NEW session there
```

## 2. Understand (task §1)
Read: the task, its linked source (requirement, spec, change, or issue), active plugin docs (`AGENTS.md §1b`), and the stack rules (`.agent/rules/stack/`).
Write the problem in your own words + links. Do NOT read archived tasks to learn the system.

## 3. Clarify (task §2)
Tick every item of the ambiguity checklist in §2 (write n/a when it does not apply); add task-specific items when needed. Ask the human in crisp batches (numbered questions with recommended answers); record Q | A | who/date.
A blocking question without an answer → stop the task (`kit-handoff`), don't guess. Low-risk unknown → `ASSUMPTION: …` line;
`kit-task verify` blocks until the human rewrites it as `CONFIRMED: …`. Never cite an id, file or API you have not seen.

## 4. Solution (task §3)
Use installed code-intelligence / LSP / grep tools to inspect callers, reuse existing code, and know the blast radius.
Respect project folder layout (`ARCHITECTURE.md`) and module boundaries (`.agent/rules/project/modules.md`).
Approach, rejected alternatives, files/modules, data + contract changes. Project-wide choice → `kit-new adr "<title>"` (`kit-adr`).

## 5. Tests first (task §4)
`.agent/scripts/kit-new testplan TASK-NNN` → one row per AC; add edge/negative/security cases (`kit-testcases`).
Write the tests, run them, **see them fail** for the expected reason (one vertical slice at a time, testing public behaviour).
Bug fix (`type: fix|hotfix`): reproduce with a failing loop first, minimise, then fix + regression test. Checkpoint: `kit-task checkpoint "tests for AC1-AC3 (red)"`.

## 6. Implement (task §5)
Small steps: minimal code to turn tests green → `.agent/scripts/kit-run check` → `kit-task checkpoint "<what works>"`.
Same error 3× or the approach no longer fits → STOP, `kit-task rollback`, add to `LESSONS.md`, re-plan.

## 6b. UI hat (task tag `ui`, or the slice has a screen)
Implement contract/backend + tests → generated client/types (if enabled) → UI components covering all 4 states (empty/loading/error/success), design tokens, keyboard/labels/contrast (a11y), component tests per state, and an e2e journey test.

## 7. Verify
All tests green, `kit-review` (in a fresh context against `kit/TASK-NNN/base`; fix BLOCKER/MAJOR), `kit-security` if input/auth/data/files/network/deps/config changed,
record it: `.agent/scripts/kit-task review "BLOCKER 0 · MAJOR 1 fixed · MINOR 2 → TASK-031 — by code-reviewer"` (verify blocks
without it, and on any BLOCKER/MAJOR marked open), walk `.agent/checklists/definition-of-done.md`, tick each AC proven by a test.
Then `.agent/scripts/kit-task verify`.

## 8. Document (task §7)
Update matching living docs in this PR (`README.md` and active plugin docs/specs/contracts).
Fill **Result**: what changed, how verified (commands/tests), docs updated, follow-up tasks created (keep PR summary concise with before/after evidence).

## 9. Finish
```bash
.agent/scripts/kit-task finish   # verify gates → kit-run check → plugin archive (if any) → push → PR
```
Update `STATE.md`, run `kit-daily`. After merge: `kit-task merged TASK-NNN`; worktree: `kit-task cleanup TASK-NNN`.

## Stop gate (Claude Code)
Ending a turn with failing `stop_checks` on uncommitted code is blocked once — fix, or explain exactly what fails.
The same failure `stop_repeat_max` turns in a row means you are patching in circles: roll back to the last green checkpoint or ask, and write `LESSONS.md`.
Each edited file is also checked at once (`check_file_<ext>`, PostToolUse hook): fix what it reports before moving to the next file.

## Never
Commit on protected branches · skip/disable/weaken tests or lint · touch secrets · change unrelated code · merge your own PR ·
bypass plugin archive/verify gates.
