---
name: kit-ba
description: Business analysis following BABOK practice — elicit, model and specify an idea or change request into docs/ba/ (brief, stakeholders, as-is/to-be process with swimlanes, use cases, sequence/state/ERD diagrams, FR/NFR, user stories with Given/When/Then, business rules, traceability matrix). Use before planning any new project, epic or non-trivial feature.
---
# kit-ba — Business Analysis (BABOK-aligned)

Output must let a planner split work into tasks and a tester derive test cases **without guessing**.
Write in `docs_language` (`.agent/project.yaml`). Diagrams follow the **kit-diagram** playbook. Templates: `docs/ba/_templates/`.

## 0. Size the work
- **Small change** (1–3 stories): only steps 2, 5, 6, 8 — extend `REQUIREMENTS.md`, one sequence diagram if it touches >1 component.
- **Feature/epic**: all steps, in `docs/ba/<feature-slug>/`.
- **New project**: all steps at project level (`docs/ba/`), then one folder per epic.

## 1. Context (read, don't ask)
`.agent/context/PROJECT.md`, `GLOSSARY.md`, existing `docs/ba/**`, `docs/architecture/**`. Prefer codegraph/grep over opening whole files.
For an existing system, derive the **as-is** behaviour from code before asking.

## 2. Elicitation — one batch of ≤ 7 questions
Only what blocks analysis: who/which roles, problem & current workaround, measurable success, constraints (legal, deadline, budget, tech),
out of scope, volumes (users, transactions/day, data size), integrations. If no human: write `ASSUMPTION:` lines and continue.

## 3. Stakeholders → `stakeholders.md` (template `stakeholders.md`)
Stakeholder list with interest/influence, RACI for decisions, user roles/personas with goals and pain points.

## 4. Process modelling → `process.md` (template `process-asis-tobe.md`)
- **As-is** (if a process exists) and **To-be** as **swimlane activity diagrams** (one lane per role/system), with decisions,
  exceptions and hand-offs. Mark pain points on as-is, improvements on to-be. Tables of steps (actor, input, output, rule).
- **Use cases**: overview diagram (template `use-case.md`) + ONE FILE per use case: `.agent/scripts/kit-new usecase "<title>"`
  → `docs/ba/use-cases/UC-NN-*.md` (actors, pre/post-conditions, main/alternative/exception flows, activity + sequence diagram).

## 5. Specification → `REQUIREMENTS.md` (+ feature files)
- FR table (ID, statement "The system shall…", MoSCoW, source goal, stories). One testable statement each.
- NFR table with **numbers** (ISO 25010 categories: performance, reliability/availability, security, usability/accessibility, maintainability, portability, compliance).
- User stories: ONE FILE each, `.agent/scripts/kit-new story "<title>" --uc UC-NN` → `docs/ba/stories/US-NN-*.md`; INVEST;
  acceptance criteria Given/When/Then incl. negative paths. Group them by epic in a **story map** (template `story-map.md`).
  These AC become OpenSpec scenarios in kit-plan, so write them observable and testable.
- Business rules `BR-NN` (calculations, validations, permissions) — referenced from stories, never duplicated.
- Data: entities + fields + validation in a **data dictionary**, **ERD** (template `data-model.md`); lifecycle → **state diagram**.
- Interactions across components/external systems → **sequence diagrams** (template `sequence.md`), include error/timeout paths.
- UI-heavy: low-fi wireframe (ASCII or simple HTML) + screen → story mapping.

## 6. Traceability → `RTM.md` (template `RTM.md`)
Goal → FR/NFR → US → AC → (TASK, Test case filled later by kit-plan / kit-testcases). No orphan FR, no story without a goal.

## 7. Validate diagrams
Run `.agent/scripts/kit-run docs` (renders every Mermaid/PlantUML block; fails on syntax errors). Fix until green.

## 8. Quality gate (all true before kit-plan)
- [ ] Every goal measurable; scope and out-of-scope explicit.
- [ ] Every FR traces to a goal and to ≥1 story; every story has testable AC incl. a negative case.
- [ ] NFRs have numbers; business rules have IDs and single source.
- [ ] Processes cover exceptions, not only the happy path; diagrams render.
- [ ] No solution design leaking into requirements unless stated as a constraint (→ kit-sa decides HOW).
- [ ] Open questions listed with owner; blockers answered.

## 9. Hand-off
Update `PROJECT.md` goals/non-goals and `GLOSSARY.md`. Summarise to the human (goals, Must-haves, open questions, diagrams produced).
Next: **kit-sa** if architecture/infrastructure is undecided, else **kit-plan** (stories → OpenSpec changes → kit tasks).
