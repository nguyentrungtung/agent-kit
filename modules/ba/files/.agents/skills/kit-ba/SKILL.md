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

## 2. Elicitation & Clarification Interview Protocol
Never assume business facts, client platforms, or security rules. If an incoming request is vague (e.g. "implement user authentication", "add checkout"), **DO NOT generate documents immediately**.
Run an elicitation round (with module eng-skills: **mp-grill-with-docs** or **mp-to-questionnaire**):
Ask **ONE batch of 3–5 focused clarifying questions** (with recommended defaults / multiple-choice options) covering:
1. **Actors & Authentication Scope:** Who logs in (End-users, Admins, Partners)? Which methods (Email+Password, Phone+OTP, Social OAuth2: Google/Apple, SSO)?
2. **Client Platforms:** Web SPA, Web SSR (Blade/Next.js), Mobile App (iOS/Android), or Public API? *(Critical input for SA to choose Session vs JWT vs OAuth2 PKCE)*.
3. **Security & Business Rules:** MFA needed? Password rules? Lock account after N failed attempts? Session duration ("Remember me")?
4. **Data Privacy (PII):** What personal data is collected? (Full name, phone, ID number — check Vietnam Law 91/2025/QH15).
5. **Exceptions & Edge Cases:** What happens if email exists? What if verification OTP expires?

Record all questions and answers in `docs/ba/BRIEF.md` under *Clarifications Q&A*. If no human is present: write `ASSUMPTION:` lines and continue.

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

## 7. Validate diagrams
Run `.agent/scripts/kit-run docs` (renders every Mermaid/PlantUML block; fails on syntax errors). Fix until green.

## 8. Quality gate (all true before kit-plan)
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
- Architectural decision questions for SA (e.g. Auth approach: Session vs JWT vs OAuth2, DB choice, sync vs async messaging)

Summarise to the human (goals, Must-haves, open questions, diagrams produced).
Next: **kit-sa** (to decide HOW, draw system sequence diagrams, and record ADRs), then **kit-plan** (to split into OpenSpec changes and tasks).
