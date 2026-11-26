---
name: kit-plan
description: Plan requirements into executable work — group deliverables (and spec changes when enabled) into vertical slices, split into one-session kit tasks with acceptance criteria and dependencies, and maintain docs/plan/ROADMAP.md. Use when planning a feature or milestone.
---
# kit-plan — from goals/stories to executable tasks

## 1. Read
`PROJECT.md` (goals), existing architecture/spec docs (`AGENTS.md §1b`, `docs/README.md`) + ADRs,
`kit-task list`, `STATE.md`. Run any installed upstream analysis plugins first if requirements/architecture have open gaps.
Gate before planning: `.agent/scripts/kit-trace` has 0 errors, and `kit-trace assumptions` is shown to the human — every
assumption that changes scope is CONFIRMED first (plans built on guesses multiply the error into every task).

## 2. Milestones
2–5 usable increments; first a **walking skeleton** (thin end-to-end slice through every layer), then features, then hardening.

## 3. Spec changes (when spec/OpenSpec plugin is installed)
For each cohesive feature group: `.agent/scripts/kit-new change <kebab-name> "<one line>"`, author proposal → specs → design → tasks, and validate `--strict`. Without a spec plugin, capture scope and AC directly in the roadmap + tasks.

## 4. Kit tasks & Sizing Guide (Sweet Spot)
Avoid splitting by horizontal layers (e.g. do NOT create separate tasks for Entity, DTO, Service, Controller — this creates micro-tasks and high overhead).
Split by **vertical slices** (a cohesive slice through all layers: DB + logic + API/UI + tests).

### Task Sizing Matrix
| Size | Scope (Lines changed) | Granularity | Execution Strategy |
|---|---|---|---|
| **S** | 50–150 lines | Bugfix, standalone utility, schema migration | Single session, direct verify & finish |
| **M** | 150–350 lines | **SWEET SPOT**: 1 complete vertical feature / endpoint | Single session; use **internal checkpoints** (`kit-task checkpoint`) at each green step; finish once |
| **L** | > 350 lines | **TOO BIG**: spans multiple aggregates or screens | **Split** into smaller vertical slices (e.g. read flow vs write flow) before coding |

Create tasks: `.agent/scripts/kit-task new "<group title>" --type feature --priority P1|P2|P3` (with `--change <name>` when using a spec plugin), set `depends_on`, and copy clear Given/When/Then ACs into each task.
Order: foundations (schema, contracts, skeleton) → features → hardening (security, performance, observability).

### Parallel Execution (Boost Velocity)
Tasks with no shared dependencies (`depends_on: []`) can run **in parallel** by separate agents using worktrees:
```bash
.agent/scripts/kit-task start TASK-001 --worktree   # Agent A in ../<repo>-TASK-001
.agent/scripts/kit-task start TASK-002 --worktree   # Agent B in ../<repo>-TASK-002
```

## 5. Roadmap
`docs/plan/ROADMAP.md`: milestones, task table, mermaid dependency graph, risks & mitigations (update any active traceability matrix too). Optional: `kit-task sync --all` (asks first).

## 6. Self-check, then ask for approval
Every goal/requirement is covered; every task has AC + `depends_on`; no cycles; first task runnable today.
Update `STATE.md` "Next up" with the first 3 tasks. Present the plan; wait for the human OK before executing.
