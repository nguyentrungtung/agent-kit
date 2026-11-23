---
task: {{ID}}
title: {{TITLE}}
change: {{CHANGE}}
updated: {{DATE}}
---
# Test cases — {{ID}} {{TITLE}}
<!-- 
Written BEFORE writing code (TDD Red-to-Green, kit-testcases).
Tiêu chuẩn Bộ 6 Ca Kiểm Thử (Core 6 Test Matrix):
- TC-01: Happy Path (Positive functional execution)
- TC-02: Boundary & Limits (BVA: min, max, empty, null, unicode)
- TC-03: Negative & Validation (Missing fields, invalid format, conflict 409)
- TC-04: Security & Access Control (Auth 401/403, IDOR/BOLA, token expiry)
- TC-05: State Transition & Business Rules (Invalid state transition, business rule violations)
- TC-06: Resilience & Concurrency (Idempotency, duplicate requests, timeouts)

Mỗi AC phải có ít nhất 1 dòng; mỗi dòng phải trỏ tới file test thật ("path/to/file::test_name") hoặc ghi "manual" kèm lý do.
-->

| ID | AC / scenario | Type | Level | Precondition / data | Steps / input | Expected | Automated in | Status |
|---|---|---|---|---|---|---|---|---|
{{ROWS}}

## Edge & negative cases checklist
- [ ] **Boundaries (BVA):** Min length, max length, 0, negative values, string trimming.
- [ ] **Validation (Negative):** Missing required fields, invalid format/regex, duplicate unique fields.
- [ ] **Security & Authorization:** Unauthenticated (401), unauthorized role (403), accessing another user's resource (IDOR).
- [ ] **State & Business Rules:** Operation rejected when resource is in invalid state (e.g. locked, deleted, completed).
- [ ] **Concurrency & Idempotency:** Duplicate submission handling, concurrency lock / optimistic lock.
- [ ] **External Failures:** Downstream service timeout, network retry, database error handling.

## Run
<!-- Command(s) that run exactly these tests, e.g. .agent/scripts/kit-run test -->
