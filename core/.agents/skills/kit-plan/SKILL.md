---
name: kit-plan
description: Plan from business analysis to executable work — group user stories into OpenSpec changes (proposal → specs → design → tasks with the kit-flow schema), split each change into one-session kit tasks with acceptance criteria and dependencies, and maintain docs/plan/ROADMAP.md. Use after kit-ba / kit-sa or when the user asks for a plan.
---
# kit-plan — from stories to changes to tasks

## 1. Read
`PROJECT.md` (goals), `docs/ba/` (UC, US, BR, NFR, RTM), `docs/architecture/` + ADRs, `openspec/specs/` (what already exists),
`kit-task list`, `STATE.md`. Missing BA → run kit-ba first. Undecided architecture → kit-sa first.

## 2. Milestones
2–5 usable increments; first a **walking skeleton** (thin end-to-end slice through every layer), then features, then hardening.

## 3. One OpenSpec change per cohesive feature
For each Must story group: `.agent/scripts/kit-new change <kebab-name> "<one line>"`, then create the artifacts in order
(Claude Code: `/openspec-propose <name>`; any agent: `.agent/scripts/kit-openspec instructions <artifact> --change <name>`):
- **proposal** — Source (UC/US/BR + goal), Clarifications (ask now, not during coding), scope, capabilities, impact.
- **specs** — every AC → scenario (named with its US/AC id), negative scenarios included.
- **design** — impact & reuse, data model, API contract, **test plan**, rules applied; ADRs for project-wide choices.
- **tasks** — `## N.` groups = one kit task each (≤ ~300 changed lines, one concern), tests first in every group.
Validate: `.agent/scripts/kit-openspec validate <name> --strict`.

## 4. Kit tasks
For each tasks.md group: `.agent/scripts/kit-task new "<group title>" --change <name> --type feature --priority P1|P2|P3`
→ put the TASK id into the group heading and the proposal's *Kit tasks*; copy the group's AC into the task; set `depends_on`.
Order: foundations (schema, contracts, skeleton) → features → hardening (security, performance, observability).

## 5. Roadmap
`docs/plan/ROADMAP.md`: milestones, change → tasks table, mermaid dependency graph, risks & mitigations.
Update `docs/ba/RTM.md` (story → change → task). Optional: `kit-task sync-gh --all` (asks first).

## 6. Self-check, then ask for approval
Every Must story is in a change; every change validates; every task has AC + depends_on; no cycles; first task runnable today.
Update STATE.md "Next up" with the first 3 tasks. Present the plan; wait for the human OK before executing.
