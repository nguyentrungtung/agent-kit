---
name: kit-task
description: Execute ONE task end-to-end with gitflow — start branch, implement in small checkpointed steps, test, review, security check, finish with a PR. Use whenever writing or changing code.
---
# kit-task — implement a task safely

## 0. Preconditions
- Task file exists with acceptance criteria. If not → kit-plan (or ask). Dependencies (`depends_on`) are done.

## 1. Start
```bash
.agent/scripts/kit-task start TASK-NNN      # branch <type>/TASK-NNN-slug + restore point kit/TASK-NNN/base
```
Read the task file fully + only the context it links. Write/adjust the **Plan** section (small steps) before coding.

**Parallel work** (several agents at once, one task each): `.agent/scripts/kit-task start TASK-NNN --worktree`
creates `../<repo>-TASK-NNN` on its own branch. Open a NEW agent session in that folder and run `kit-run install` there.
Never work on two tasks in the same folder. See all: `kit-task worktrees` · `.agent/scripts/kit-board`.

## 2. Loop per step (keep each step small)
1. Write/adjust a test for the step first when practical (red).
2. Implement the minimum to pass (green). Follow CONVENTIONS.md and module boundaries in ARCHITECTURE.md.
3. Run the relevant gate: `.agent/scripts/kit-run lint test` (or `check`).
4. Green → `.agent/scripts/kit-task checkpoint "<what now works>"` (restore point + remote backup).
5. Red 3 times on the same problem, or the approach looks wrong → STOP. Use **kit-rollback**, add a line to LESSONS.md, re-plan.
6. Append one line to the task file *Progress log* for meaningful progress or decisions.

## 3. Verify
- **kit-testcases** → test cases in `docs/qa/TASK-NNN.md`, implemented as automated tests.
- **kit-review** (code-reviewer sub-agent) → fix BLOCKER/MAJOR.
- **kit-security** for anything touching input, auth, data, files, network, deps, config.
- Walk `.agent/checklists/definition-of-done.md`; tick acceptance criteria in the task file.

## 4. Finish
```bash
.agent/scripts/kit-task finish     # runs kit-run check, pushes, opens PR to develop (main for hotfix)
```
Update `STATE.md`, run **kit-daily**. After the human merges: `.agent/scripts/kit-task merged TASK-NNN`,
and for worktree tasks `kit-task cleanup TASK-NNN` from the main checkout.
If the project tracks work in GitHub Issues: `kit-task sync-gh TASK-NNN` (asks the human first; the PR body then says `Closes #N`).

## Stop gate (Claude Code)
When you end a turn on a task branch with uncommitted code, the Stop hook runs `stop_checks` (default `format_check lint`).
If it blocks, fix the reported errors — never relax configs — or tell the user exactly what fails and why.

## Never
Commit on protected branches · skip/disable tests or lint · touch secrets · change unrelated code · merge your own PR.
