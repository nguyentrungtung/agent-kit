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

## 2. Elicitation interview — MANDATORY before writing any requirement
Never assume business facts. **Do not generate BA documents until a clarification round has been answered** — a document built
on guesses is the main source of "the AI built the wrong thing". Technique: with module eng-skills use **mp-grill-with-docs**
(grill against existing docs) or **mp-to-questionnaire** (one numbered questionnaire); otherwise follow the protocol below.

**Protocol (every new project / epic / vague request):**
1. Read context first (step 1) and cross out what the docs/code already answer — never ask what you can read.
2. Ask **ONE batch of 3–6 questions** (fewer than 3 only for a one-story change; more than 6 → next round). Pick them from the
   **6 dimensions** below, highest risk of building the wrong thing first. Cover at least dimensions **A, B, C** in the first round.
3. Each question: numbered, **closed** (options a/b/c or a number), with **your recommended answer** and why in ≤ 1 line —
   the human may reply "1a 2 ok 3c". Open questions only for goals.
4. Record every Q and A in `docs/ba/BRIEF.md` › *Clarifications Q&A* (who, date). Unanswered + blocking → stop and wait.
5. No human available → write each unknown as `ASSUMPTION: <your recommended answer>` and continue. `kit-trace` lists them and
   `kit-task finish` blocks on them until a human rewrites each as `CONFIRMED: <answer> (who, date)`.
6. Repeat a round after modelling (step 4) if new unknowns appear (exceptions, states, rules).

| Dim | Ask about | Example questions (adapt to the domain — do not copy) |
|---|---|---|
| **A. Goal & success** | business outcome, measurable target, deadline | "Success after 3 months = (a) X orders/day (b) −Y% handling time (c) other?" |
| **B. Users & permissions** | actors, roles, who may do/see what, multi-tenant? | "Who approves a refund: (a) any staff (b) manager only (c) amount-based rule?" |
| **C. Scope** | must-have vs later, explicit out-of-scope, MVP cut | "Is export to Excel in the MVP? (rec: no — later)" |
| **D. Data & rules** | key entities/fields, validations, calculations, lifecycle/states, PII & legal (VN: Law 91/2025/QH15, Decree 13/2023) | "Can an order be edited after payment? (a) never (b) until shipped (c) by admin" |
| **E. Scale & quality** | users, volumes, peak, latency, availability, retention, languages, devices | "Peak concurrent users: (a) <100 (b) 100–1k (c) >1k?" |
| **F. Context & constraints** | client platforms (web SPA/SSR, mobile, public API), integrations, legacy, budget, team, compliance | "Payment via (a) VNPay (b) MoMo (c) bank transfer only?" |
Domain packs (use only when relevant): **auth** → login methods, MFA, lockout, session length; **payments** → refunds, partial
payment, reconciliation; **reporting** → freshness, drill-down, export; **workflow** → approvals, SLAs, escalation.

## 3. Stakeholders → `stakeholders.md` (template `stakeholders.md`)
Stakeholder list with interest/influence, RACI for decisions, user roles/personas with goals and pain points.

## 4. Process modelling → `process.md` (template `process-asis-tobe.md`)
- **As-is** (if a process exists) and **To-be** as **swimlane activity diagrams** (one lane per role/system), with decisions,
  exceptions and hand-offs. Mark pain points on as-is, improvements on to-be. Tables of steps (actor, input, output, rule).
- **Use cases**: overview diagram (template `use-case.md`) + ONE FILE per use case: `.agent/scripts/kit-new usecase "<title>"`
  → `docs/ba/use-cases/UC-NN-*.md` (actors, pre/post-conditions, main/alternative/exception flows, activity + sequence diagram).

## 5. Specification with EARS & INVEST → `REQUIREMENTS.md` (+ feature files)
- **Functional Requirements using EARS (Easy Approach to Requirements Syntax)**:
  Every requirement MUST be unambiguous and testable using one of the EARS patterns:
  - *Event-driven:* **WHEN** `<trigger>`, the system SHALL `<response>`. (e.g. *WHEN the user submits valid credentials, the system SHALL authenticate and issue an active session.*)
  - *State-driven:* **WHILE** `<in state>`, the system SHALL `<response>`. (e.g. *WHILE an account is locked, the system SHALL deny all login attempts.*)
  - *Unwanted behavior:* **IF** `<error/unwanted condition>`, **THEN** the system SHALL `<response>`. (e.g. *IF 5 consecutive failed login attempts occur, THEN the system SHALL lock the account for 15 minutes.*)
  - *Optional:* **WHERE** `<feature enabled>`, the system SHALL `<response>`. (e.g. *WHERE 2FA is enabled, the system SHALL request an OTP before completing authentication.*)
  - *Ubiquitous:* The system SHALL `<response>`.
- **NFR table with numbers** (ISO 25010: p95 latency, availability 99.9%, password hashing standards).
- **User stories**: ONE FILE each, `.agent/scripts/kit-new story "<title>" --uc UC-NN` → `docs/ba/stories/US-NN-*.md`; INVEST;
  acceptance criteria Given/When/Then incl. negative paths. Group them by epic in a **story map** (template `story-map.md`).
  These AC become OpenSpec scenarios in kit-plan, so write them observable and testable.
- **Business rules `BR-NN`** (calculations, validations, permissions) — referenced from stories, never duplicated.
- **Data**: entities + fields + validation in a **data dictionary**, **ERD** (template `data-model.md`); lifecycle → **state diagram**.
- **Interactions across components/external systems** → **sequence diagrams** (template `sequence.md`), include error/timeout paths.
- **UI & Screen Specification (Crucial for Full-stack Dev & Frontend)**:
  For any user-facing feature, specify in the story (`docs/ba/stories/US-NN-*.md`):
  1. **User Flow & Navigation:** Entry point, triggers, navigation paths.
  2. **Screen Wireframe / Layout:** Low-fi layout using ASCII art, Markdown tables, or Mermaid layout diagrams.
  3. **The 4 Essential UI States:**
     - *Empty State:* Display when zero data exists / initial load.
     - *Loading State:* Skeletons, spinners, disabled action buttons.
     - *Error State:* Field-level validation messages, banner alerts for 4xx/5xx failures.
     - *Success State:* Toast notification, feedback message, or view transition.
  This gives the Full-stack Developer unambiguous visual and interactive specifications to implement the frontend cleanly.

## 6. Traceability → `RTM.md` (template `RTM.md`)
Goal → FR/NFR → US → AC → (TASK, Test case filled later by kit-plan / kit-testcases). No orphan FR, no story without a goal.

## 7. Validate diagrams & traceability
Run `.agent/scripts/kit-run docs` (renders every Mermaid/PlantUML block; fails on syntax errors) and `.agent/scripts/kit-trace`
(every UC/US/BR/FR id referenced exists; warns on stories without UC/AC/negative AC, FRs without stories). Fix until green.

## 8. Quality gate (all true before kit-plan)
- [ ] Clarification round answered (≥ 3 questions covering dimensions A, B, C) and recorded in BRIEF.md; open `ASSUMPTION:` lines listed for the human (`kit-trace assumptions`).
- [ ] `kit-trace` has 0 errors.
- [ ] Every goal measurable; scope and out-of-scope explicit.
- [ ] Every FR traces to a goal and to ≥1 story; every story has testable AC incl. a negative case.
- [ ] NFRs have numbers; business rules have IDs and single source.
- [ ] Processes cover exceptions, not only the happy path; diagrams render.
- [ ] No solution design leaking into requirements unless stated as a constraint (→ kit-sa decides HOW).
- [ ] Open questions listed with owner; blockers answered.

## 9. Hand-off (BA → SA → Planner)
Update `PROJECT.md` goals/non-goals and `GLOSSARY.md`.
Deliver the **Architecture Hand-off Packet** in `docs/ba/BRIEF.md`:
- Client platforms (Web SPA, Web SSR, Mobile App, API)
- Expected load, transaction volume, and latency numbers (from NFRs)
- Required external integrations (OAuth providers, payment gateways, legacy systems)
- The **3–5 hardest business rules / calculations** (e.g. pricing, scheduling, allocation, approval routing) — SA designs the algorithm for them
- Architectural decision questions for SA (e.g. Auth approach: Session vs JWT vs OAuth2, DB choice, sync vs async messaging)

Summarise to the human (goals, Must-haves, open questions, diagrams produced).
Next: **kit-sa** (to decide HOW, draw system sequence diagrams, and record ADRs), then **kit-plan** (to split into OpenSpec changes and tasks).
