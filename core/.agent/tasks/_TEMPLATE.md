---
id: {{ID}}
title: {{TITLE}}
status: todo
type: {{TYPE}}
priority: {{PRIORITY}}
tags: {{TAGS}}
template: 2
goal_ref: G?
change: {{CHANGE}}
depends_on: []
assignee:
branch:
worktree:
issue:
created: {{DATE}}
started:
done:
---
# {{ID}} — {{TITLE}}
<!-- Workflow (kit-task playbook): 1 Understand → 2 Clarify → 3 Solution → 4 Tests first → 5 Implement → 6 Verify → 7 Document → 8 Finish.
     `kit-task verify` / `finish` refuse until: §1 links a source, the §2 checklist is fully ticked and every question answered,
     §3/§4/§7 are filled, every AC is ticked and tested, no `ASSUMPTION:` is left unconfirmed, ids resolve (kit-trace),
     and (feature) a spec / living doc changed with the code, and a code review is recorded (`kit-task review "…"`). -->

## 1. Understand
<!-- In your own words: the problem, who is affected, expected outcome. Link the source: OpenSpec change (openspec/changes/<change>/),
     use case / user story / business rule ids (docs/ba/), spec capability (openspec/specs/…).
     No change and no UC/US/BR id? Write a line "Source: <issue / request, who, date>". Never invent ids — kit-trace checks them. -->

## 2. Clarifications
<!-- Walk EVERY item BEFORE designing and tick it: when the answer is known (from docs or the human), or when it does not apply —
     then tick it too and add "n/a: <why>" after it (e.g. "- [x] Integrations — n/a: no external calls"). An unticked box blocks verify.
     Unknown + blocking → ask the human ONE batch and stop until answered. Unknown + low-risk → "ASSUMPTION: …" line;
     only a human turns it into "CONFIRMED: <answer> (who, date)" — finish is blocked while any ASSUMPTION is open here, in the
     change, in docs/ba/BRIEF.md or in docs/architecture/SOLUTION.md. -->
- [ ] Actor & permission — who, which role, what if unauthorized
- [ ] Data & validation — fields, types, required, limits, uniqueness, defaults
- [ ] Edge cases — empty, max size, duplicates, concurrency, partial failure, retries/idempotency
- [ ] Errors — what the user/caller sees for each failure (status, message)
- [ ] Numbers — volumes, latency, timeouts, page sizes, retention
- [ ] State — allowed states and transitions
- [ ] Integrations — who calls whom, contract owner, other side down
- [ ] Scope — what is explicitly NOT part of this task

| # | Question | Answer | Who / date |
|---|---|---|---|

## Acceptance criteria
<!-- Given/When/Then. Copied from the story / spec scenarios. Ticked only when an automated test proves it. -->
- [ ] AC1 — Given … When … Then …

## Out of scope

## 3. Solution
<!-- Approach + rejected alternatives; reuse found (codegraph explore/impact); files/modules touched; data/API changes
     (details in the change's design.md). Project-wide decision → kit-adr. -->

## 4. Test plan
<!-- Link docs/qa/{{ID}}.md (create: .agent/scripts/kit-new testplan {{ID}}). Tests are written and seen failing BEFORE the code. -->

## 5. Implementation steps
<!-- Small verifiable steps; each ends green (kit-run check) + kit-task checkpoint. -->
1.

## 7. Result
<!-- Filled before finish: what changed (behaviour, files), how it was verified (tests, commands), living docs updated
     (openspec/specs via the change, docs/api, docs/architecture, README), follow-ups created as new tasks.
     A feature that needs no doc change says so explicitly: "Docs: none — <why>". -->

## Risks / rollback notes

## Progress log
<!-- Newest first. kit-task writes checkpoints here; record the review with: kit-task review "BLOCKER 0 · MAJOR 1 fixed · MINOR 2 → TASK-031 — by code-reviewer" -->
- {{DATE}} — created

## Handoff notes
<!-- Written by kit-handoff: exact next step, open questions, gotchas. -->
