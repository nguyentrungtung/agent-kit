---
name: kit-task
description: Execute ONE task end-to-end with the agent-kit workflow — understand, clarify, design the solution, write tests first, implement in checkpointed steps, verify, document, finish with a PR (gitflow, restore points, OpenSpec change validation/archive). Use whenever writing or changing code.
---
# kit-task — implement one task the same way every time

Rules: `.agent/rules/core/workflow.md` (the 8 steps + ambiguity checklist). Every step writes into the task file.

## 0. Preconditions
- A task file exists (`.agent/scripts/kit-task new "<title>" --change <change>` / `kit-new task`). No task → kit-plan or ask.
- `depends_on` tasks are done. If the task belongs to an OpenSpec change, its proposal/specs/design/tasks exist and validate.

## 1. Start
```bash
.agent/scripts/kit-task start TASK-NNN            # branch <type>/TASK-NNN-slug + restore point kit/TASK-NNN/base
.agent/scripts/kit-task start TASK-NNN --worktree # parallel: ../<repo>-TASK-NNN, open a NEW session there
```

## 2. Understand (task §1)
Read: the task, its change (`openspec/changes/<change>/`), linked UC/US/BR in `docs/ba/`, the current spec of the
capability (`.agent/scripts/kit-openspec show <capability> --type spec`), the stack rules (`.agent/rules/stack/`).
Write the problem in your own words + links. Do NOT read archived tasks to learn the system.

## 3. Clarify (task §2)
Tick every item of the ambiguity checklist in §2 (write n/a when it does not apply); add task-specific items when the task needs them. Ask the human in rounds — with module eng-skills use **mp-grilling** (numbered questions, your
recommended answer each, only the questions whose prerequisites are settled); record Q | A | who/date. Nothing to ask → every checklist item is still ticked (with "n/a: <why>" where it does not apply).
A blocking question without an answer → stop the task (kit-handoff), don't guess. Low-risk unknown → `ASSUMPTION: …` line;
`kit-task verify` blocks until the human rewrites it as `CONFIRMED: …`. Never cite an id, file or API you have not seen.

## 4. Solution (task §3)
`codegraph explore "<area>"` / `codegraph impact <symbol>` → reuse existing code, know the blast radius.
Place files by `docs/architecture/project-structure.md`; respect `.agent/rules/project/modules.md` (new module or dependency → stop, ask SA/human).
Hard rule from SOLUTION.md §7b (hotspot)? → implement the chosen pattern/algorithm, not an ad-hoc one.
Approach, rejected alternatives, files/modules, data + API changes (details belong in the change's `design.md`).
Project-wide choice → `kit-new adr "<title>"` then the kit-adr playbook.

## 5. Tests first (task §4)
`.agent/scripts/kit-new testplan TASK-NNN` → one row per AC; add edge/negative/security cases (kit-testcases playbook).
Write the tests, run them, **see them fail** for the expected reason (discipline: **mp-tdd** — one vertical slice at a time,
test behaviour through the public interface, mock only at system boundaries).
Bug fix (`type: fix|hotfix`): first **mp-diagnosing-bugs** — reproduce with a loop that goes red, minimise, then fix + regression test. Checkpoint: `kit-task checkpoint "tests for AC1-AC3 (red)"`.

## 6. Implement (task §5)
Small steps: minimal code to turn tests green → `.agent/scripts/kit-run check` → `kit-task checkpoint "<what works>"`.
Same error 3× or the approach no longer fits → STOP, `kit-task rollback`, add to LESSONS.md, re-plan.
Tick tasks.md items of the change as their verification passes.

## 6b. UI hat (task tag `ui`, or the slice has a screen)
Order inside the slice: contract (`docs/api/openapi.yaml`) → `kit-run apigen` → backend + tests → feature hook on the generated types →
components/pages. Use only tokens/components from `docs/architecture/ui-design-system.md`; implement the story's wireframe and all
4 states (empty/loading/error/success); keyboard + labels + contrast (a11y); component tests per state, one e2e per user journey.

## 7. Verify
All tests green, `kit-review` (two-axis review via **mp-code-review** against `kit/TASK-NNN/base`; fix BLOCKER/MAJOR), `kit-security` if input/auth/data/files/network/deps/config changed,
record it: `.agent/scripts/kit-task review "BLOCKER 0 · MAJOR 1 fixed · MINOR 2 → TASK-031 — by code-reviewer"` (verify blocks
without it, and on any BLOCKER/MAJOR marked open), walk `.agent/checklists/definition-of-done.md`, tick each AC proven by a test.
Then `.agent/scripts/kit-task verify`.

## 8. Document (task §7)
Update living docs in this PR: spec deltas in the change, `docs/api` (OpenAPI), `docs/architecture`, README.
Fill **Result**: what changed, how verified (commands/tests), docs updated, follow-up tasks created.
The PR body follows **mp-pr** (smallest visual summary, before/after evidence, merge danger: one-way/two-way door + blast radius).

## 9. Finish
```bash
.agent/scripts/kit-task finish   # verify gates → kit-run check → archive OpenSpec change if last task → push → PR
```
Update STATE.md, run kit-daily. After merge: `kit-task merged TASK-NNN`; worktree: `kit-task cleanup TASK-NNN`.

## Stop gate (Claude Code)
Ending a turn with failing `stop_checks` on uncommitted code is blocked once — fix, or explain exactly what fails.

## Never
Commit on protected branches · skip/disable/weaken tests or lint · touch secrets · change unrelated code · merge your own PR ·
run `openspec archive` by hand.
