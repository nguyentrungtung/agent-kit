---
name: kit-plan
description: Full planning — from BA requirements to milestones, a dependency-ordered task list (one session each) with acceptance criteria and test approach; creates task files and docs/plan/ROADMAP.md. Use after kit-ba or when the user asks for a plan.
---
# kit-plan — from requirements to executable tasks

## Steps
1. Read: `PROJECT.md`, `ARCHITECTURE.md`, `docs/ba/REQUIREMENTS.md`, `DECISIONS.md`, `STATE.md`, open tasks (`kit-task list`).
2. **Design first, briefly:** for each Must story decide where it lives (module/layer), data changes, API contract.
   Any real choice (library, schema, pattern) → one `kit-adr` each. Update `ARCHITECTURE.md` if structure changes.
3. **Milestones:** 2–5, each a usable increment (walking skeleton first: end-to-end thin slice before breadth).
4. **Split into tasks** — each task:
   - fits ONE session (≈ ≤ 300 changed lines, ≤ ~8 files), one concern, mergeable alone (feature flag if needed);
   - has Goal (→ goal/story id), Acceptance criteria (Given/When/Then), Plan steps, test approach, risks, `depends_on`;
   - order: foundations (schema, contracts, skeleton) → features → hardening (security, perf, observability).
   Create with `.agent/scripts/kit-task new "<title>" --type feature|fix|chore --priority P1|P2|P3`, then fill the file.
5. Write `docs/plan/ROADMAP.md`: milestones, task table, mermaid dependency graph, risks & mitigations, traceability (story → tasks).
6. **Self-check:** every Must story covered; no task without AC; no circular deps; first task is runnable today.
7. Update `STATE.md` "Next up" with the first 3 tasks. Present the plan summary; get human OK before executing.
