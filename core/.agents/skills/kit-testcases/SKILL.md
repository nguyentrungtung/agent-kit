---
name: kit-testcases
description: QA — derive test cases from acceptance criteria (positive, negative, boundary, error, security, regression), write docs/qa/TASK-NNN.md and implement them as automated tests. Use for every task before finish, or when asked to "write tests" / "test plan".
---
# kit-testcases — test design + automation (ISTQB-aligned)

Delegate to the `qa-engineer` sub-agent when available (give it the task file + changed files list).

## 1. The Core 6 Test Matrix (Tối thiểu 5–6 ca kiểm thử bắt buộc)
For any non-trivial feature or API endpoint, you MUST derive test cases covering at least these **6 critical testing angles**:

| # | Test Angle | Objective & Technique | Example (e.g. User Registration / API) |
|---|---|---|---|
| **TC-01** | **Happy Path** (Positive) | Verify standard functional execution with valid inputs | Valid email & strong password → 201 Created, user saved in DB |
| **TC-02** | **Boundary & Limits** (BVA) | Test min/max lengths, numeric limits, empty strings, trimming | Password length = 8 (pass), 7 (fail); Name length = 255 (pass), 256 (fail); spaces trimmed |
| **TC-03** | **Negative & Validation** (Equivalence) | Missing fields, malformed syntax, duplicate resources | Invalid email format → 422 Unprocessable; Duplicate email → 409 Conflict with RFC 9457 error |
| **TC-04** | **Security & Access Control** | AuthN, AuthZ, token expiration, IDOR/BOLA | No token → 401; User A attempts to edit User B's profile → 403 Forbidden |
| **TC-05** | **State Transition & Business Rules** | Test valid/invalid state changes and business logic | Locked account attempts login → denied; Expired activation token → rejection |
| **TC-06** | **Resilience, Concurrency & Idempotency** | Race conditions, duplicate requests, network failure | Sending 2 identical payment/create requests concurrently → only 1 processed (Idempotency key) |

## 2. Steps to Execute
1. **Inputs:** `.agent/checklists/testing.md`, task acceptance criteria (AC), business rules (`docs/ba/`), and code diff (`git diff kit/TASK-NNN/base`).
2. **Generate Test Plan Document:** Run `.agent/scripts/kit-new testplan TASK-NNN` to create `docs/qa/TASK-NNN.md`.
3. **Flesh out the Matrix:** Populate each AC into the standard test table with at least the relevant Core 6 angles:
   - Each automated case must point to an explicit test reference: `path/to/test_file.ext::test_function_name`.
   - Manual tests (e.g. visual layout check) must explicitly record `manual` in the "Automated in" column along with a clear rationale.
4. **Automate (TDD Red-to-Green):**
   - Write tests **BEFORE** the implementation code; verify they fail for the intended reason (Red).
   - Implement minimal code to pass (Green).
   - Tests must be **deterministic**: no `sleep()`, mocked clock/time, synthetic fixtures, isolated DB/containers (Testcontainers/compose).
5. **Run & Verify:**
   - Run `.agent/scripts/kit-run test` and `kit-run testcov` (ensure changed code meets `coverage_min`).
   - Run `.agent/scripts/kit-task verify` (machine-enforced gate: checks that every AC is mapped to an automated test). Link the test plan in Task §4.
