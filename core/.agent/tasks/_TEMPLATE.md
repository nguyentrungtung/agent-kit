---
id: {{ID}}
title: {{TITLE}}
status: todo
type: {{TYPE}}
priority: {{PRIORITY}}
tags: {{TAGS}}
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
     `kit-task finish` refuses until sections 1, 3, 4 and 7 are filled and every acceptance criterion is ticked. -->

## 1. Understand
<!-- In your own words: the problem, who is affected, expected outcome. Link the source: OpenSpec change (openspec/changes/<change>/),
     use case / user story / business rule ids (docs/ba/), spec capability (openspec/specs/…). -->

## 2. Clarifications
<!-- Every ambiguity, asked BEFORE designing. Blocking question without answer = stop and ask. "None" if nothing was unclear. -->
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
     (openspec/specs via the change, docs/api, docs/architecture, README), follow-ups created as new tasks. -->

## Risks / rollback notes

## Progress log
- {{DATE}} — created

## Handoff notes
<!-- Written by kit-handoff: exact next step, open questions, gotchas. -->
