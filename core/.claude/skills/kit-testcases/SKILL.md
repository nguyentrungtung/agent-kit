---
name: kit-testcases
description: QA — derive test cases from acceptance criteria (positive, negative, boundary, error, security, regression), write docs/qa/TASK-NNN.md and implement them as automated tests. Use for every task before finish, or when asked to "write tests" / "test plan".
---
# kit-testcases — test design + automation

Delegate to the `qa-engineer` sub-agent when available (give it the task file + changed files list).

## Steps
1. Inputs: task acceptance criteria, related user stories/business rules (`docs/ba/`), the diff (`git diff kit/TASK-NNN/base`).
2. **Design** cases with techniques: equivalence partitions, boundary values, decision tables (rules), state transitions,
   error guessing; plus security (invalid/malicious input, unauthorized access) and regression for fixed bugs.
3. Create `docs/qa/TASK-NNN.md` with `.agent/scripts/kit-new testplan TASK-NNN` (one row per AC), then complete it:

| ID | AC | Type (unit/integration/e2e) | Precondition | Steps / input | Expected | Automated in |
|---|---|---|---|---|---|---|
| TC-01 | AC1 | unit | … | … | … | `path/to/test::name` |

4. **Automate**: follow the project's existing test style/framework; tests are deterministic (fake clock, no real network,
   containers for DB if the project uses them), independent, named after behaviour.
5. Run `.agent/scripts/kit-run test` (+ coverage if configured; aim ≥ `coverage_min` on changed code).
6. Every AC must map to ≥ 1 passing automated test, or be listed as "manual" with a reason. Link the file from task §4.
   Tests are written BEFORE the implementation and must fail first (red → green). `kit-task verify` checks every AC is in the plan.
