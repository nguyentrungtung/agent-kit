## Summary
<!-- What & why in 2–4 lines. Link the task: TASK-NNN -->

## Changes
-

## How it was tested
- [ ] Unit tests added/updated (cases listed in `docs/qa/TASK-NNN.md`)
- [ ] Integration / e2e where behaviour crosses a boundary
- [ ] Manual check steps (if any):

## Definition of Done (`.agent/checklists/definition-of-done.md`)
- [ ] Acceptance criteria of the task all met
- [ ] `kit-run check` green locally; CI green
- [ ] No secrets, no `.env`, no debug code / commented-out code
- [ ] Security checklist reviewed (`.agent/checklists/security.md`) — input validation, authz, logging w/o PII
- [ ] Docs updated: task file progress log, ADR if a decision was made, README/API docs if behaviour changed
- [ ] Backward compatible, or migration + rollback plan written below

## Risk & rollback
- Risk level: low / medium / high
- Rollback: `kit-task revert TASK-NNN` (creates a revert PR) · data migrations: <how to undo>
