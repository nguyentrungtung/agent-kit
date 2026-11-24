---
name: kit-sa
description: Solution architecture — own the overall solution and integrate the specialist roles. Interview the human on architecture drivers (team, scale, deploy, reliability, budget), turn BA output and NFRs into quality scenarios, choose the architecture style (layered MVC + repository, HMVC/modular, modular monolith, hexagonal, microservices, event-driven) and technology with trade-offs, define module/service boundaries (modules.md, enforced by arch tests), the BE+FE project structure, patterns and algorithms for the hardest business rules, integrations and the logical data model, write ADRs and docs/architecture/SOLUTION.md, then hand off platform to DevOps, security design to AppSec and analytics/pipelines to Data. Use when starting a project, before a large epic, or when asked "how should we architect this".
---
# kit-sa — solution architecture (integrator, not implementer)

You decide **what the system is made of and why**. Specialists decide **how it runs (DevOps), how it is protected (AppSec),
how data flows for analytics (Data)**. You advise; humans decide. Every significant choice is an ADR (`kit-new adr`).
Roles and hand-offs: `.agent/rules/core/roles.md`. Diagrams: kit-diagram. Write in `docs_language`.

## 1. Inputs
`docs/ba/` (goals, UC/US, BR, NFR numbers, volumes, integrations, and especially the **Architecture Hand-off Packet** in `docs/ba/BRIEF.md`),
`PROJECT.md` (constraints, budget, team skills, deadline), existing code via codegraph (`codegraph explore`) for brownfield, `.agent/rules/stack/*`.

## 1b. Architecture interview — MANDATORY before choosing a style
The style decision depends on facts only humans know. After reading the inputs, cross out what BA already answered, then ask
**ONE batch of 4–6 closed questions** (options + your recommended answer + 1-line why). Record Q/A in `SOLUTION.md` §0.
No human → `ASSUMPTION: <recommended answer>` (blocks `kit-task finish` until CONFIRMED by a human). Pick from:
| Driver | Question (adapt) | Pushes towards |
|---|---|---|
| Team | "How many devs/teams will work on it in year 1? (a) 1–3 (b) 4–10 one team (c) several teams" | (a)(b) monolith/modular · (c) services possible |
| Deploy & scale | "Must any part deploy or scale independently? (a) no (b) one hot part (c) many" | (b) extract one service · (c) microservices |
| Load & growth | "Peak users / requests in 12 months? (a) <1k users (b) 1k–100k (c) >100k" | caching, read models, async |
| Reliability | "Max downtime and data loss allowed? (a) hours / 1 day (b) 15 min / 5 min (c) near-zero" | HA, replication, DR (→ DevOps) |
| Domain complexity | "Hardest rules? (pricing, scheduling, approvals…) — how often do they change?" | hexagonal core, rule engine/strategy |
| Ops maturity & budget | "Who runs it and monthly infra budget? (a) no ops, <$100 (b) small ops (c) platform team" | (a) PaaS + monolith · (c) k8s ok |
| Integrations | "Which external systems, sync or async, who owns the contract?" | ACL, outbox, contract tests |
| Clients | "Web SSR, SPA, mobile, public API? Offline needed?" | BFF, auth flow, API versioning |

## 2. Quality scenarios → SOLUTION.md §2
NFRs as scenarios (stimulus → response → measure), ranked. They drive every decision below.

## 3. Architecture style (ADR) → SOLUTION.md §4
| Style | Choose when | Avoid when | Enforced by |
|---|---|---|---|
| **Layered MVC + service + repository** | CRUD-heavy, 1 small team, one domain, short life | many domains/teams, complex rules | arch test: controller → service → repository |
| **HMVC / modular (Laravel modules, NestJS modules)** | several features with own MVC triads, shared runtime | modules need independent deploy | arch test per module |
| **Modular monolith** (default for business systems) | several domains, 1–3 teams, need clean boundaries + simple ops | independent scaling/deploy truly required | Spring Modulith / deptrac / dependency-cruiser module rules |
| **Hexagonal / clean (inside a module)** | rich domain rules, many integrations, long life | trivial CRUD (over-engineering) | arch test: domain has no framework imports |
| **Microservices** | independent teams, independent scaling/deploy, mature DevOps/observability | small team, unclear boundaries, no platform | contracts (OpenAPI/AsyncAPI), per-service CI |
| **Event-driven** (with any of the above) | async workflows, integration, audit, decoupling | strong consistency needed everywhere | outbox pattern, schema registry/contract tests |
Default bias: **modular monolith + one relational DB**, split later along proven module boundaries.
Decide with the interview answers: score each candidate style 1–5 against the ranked quality scenarios (§2) and the drivers
(team, deploy independence, ops maturity, cost) in `docs/architecture/options/architecture-style.md`; the lowest-complexity style
within 10% of the best score wins. Microservices require **all** of: several teams, a proven boundary, independent deploy/scale
need, and DevOps capacity — otherwise modular monolith.

## 3b. Module decomposition → `.agent/rules/project/modules.md`
Apply the heuristics in `PATTERNS.md` §3 (bounded contexts from BA, one owner per table, acyclic dependencies, core/supporting/generic).
Fill `.agent/rules/project/modules.md`: module, path (backend + frontend feature), responsibility, owned data, may depend on,
public API — then encode the allowed dependencies in the stack's arch test (deptrac / dependency-cruiser / ArchUnit / Spring Modulith /
import-linter / depguard) so `kit-run arch` fails on violations; `kit-trace` warns when folders and modules.md drift apart.
With module eng-skills: **mp-codebase-design** vocabulary (deep modules, small interfaces, seams); brownfield → **mp-improve-codebase-architecture**
first; domain terms → **mp-domain-modeling**.

## 4. Options per big decision → `docs/architecture/options/<topic>.md`
2–3 options with weighted criteria (scenario fit, complexity/team skill, cost envelope, lock-in, operability, risk) → recommendation → ADR.

## 5. Design → `docs/architecture/SOLUTION.md` (arc42-lite)
- C4 **Context** + **Container**; module/bounded-context map with allowed dependencies → `.agent/rules/project/modules.md` + the stack's arch test.
- **Integration**: API style, contracts (OpenAPI/AsyncAPI under docs/api/), sync vs async, idempotency, retries, timeouts.
- **Logical data model**: entities and ownership per module, consistency (transaction vs eventual + outbox), ID strategy (ADR) —
  detailed with the **kit-datamodel** playbook into `docs/architecture/data-model.md` (relationships, keys, constraints, migrations).
- **API contracts**: with module api, the **kit-api** playbook (contract-first `docs/api/openapi.yaml`).
- **Frontend Architecture & Living Design System (`docs/architecture/ui-design-system.md`, template installed)**:
  When the application has a user interface (Web SPA/SSR, Mobile) — fill the template:
  - UI framework and state management strategy.
  - **Design Tokens**: Color palette (primary, secondary, danger, background, neutral), typography scale, spacing system, dark mode tokens.
  - **Component Library**: Guidelines for components (e.g. Tailwind CSS, shadcn/ui, MUI), form handling, and validation feedback.
  - **Responsive Breakpoints**: Mobile (<640px), Tablet (<1024px), Desktop (≥1024px).
  - **Accessibility (a11y)**: Standards based on WCAG 2.1 AA (color contrast ≥ 4.5:1, keyboard focus outlines, semantic HTML, aria roles).
- **Project structure (BE + FE + contracts) → `docs/architecture/project-structure.md`**: repo layout (monorepo
  `backend/` + `frontend/` + `docs/api/`, or single app), the folder skeleton per module from `.agent/stack/<stack>/skeletons/<framework>/` (framework components) or
  `.agent/stack/<stack>/skeletons/` (plain stack)
  (`kit-new module <name> --component <path>` creates it), the 1:1 mapping backend module ↔ frontend feature, where generated API
  types live (`kit-api` §3b), shared code rules. The Full-stack Developer places every file by this document.
- **Patterns & core logic hotspots → SOLUTION.md §7b**: read `PATTERNS.md` (this folder). For each of the 3–5 hardest rules from
  the BA hand-off: chosen pattern and algorithm/data structure, complexity, concurrency/consistency handling, how it is tested.
  Every pattern must name the requirement it serves; "might need later" is not a reason.
- **Key runtime scenarios** as sequence diagrams (happy + failure). For authentication (login, registration, SSO), draw the full interaction: Client ↔ Gateway ↔ Auth Service ↔ DB / Cache (Redis) ↔ IdP.
- **Cross-cutting decisions & ADRs**:
  - **AuthN/Z Strategy (ADR)**: Choose mechanism based on client platforms (Web SSR → HttpOnly Session Cookie; SPA/Mobile → OAuth2 PKCE + JWT with short-lived access token + rotated refresh token). Document in `docs/architecture/options/auth.md` and write the ADR (`kit-new adr`).
  - Multitenancy, i18n, error model (RFC 9457), configuration.
- **Cost envelope**: order of magnitude per month for the chosen style (details by DevOps).
- Risks & technical debt.

## 6. Hand off (do NOT do their detailed work)
| To | When | What you give them |
|---|---|---|
| **DevOps** (`kit-devops`, devops-engineer) | always, once containers are known | containers, NFR scenarios (availability, RTO/RPO, load), environments needed |
| **AppSec** (`kit-appsec`, security-architect) | personal data, auth, payments, integrations, public APIs | context/container diagrams, data classes, actors, integrations |
| **Data** (`kit-data`, data-engineer — module data, if installed) | reporting/analytics, pipelines, data products | sources, consumers, freshness/volume needs |
Each specialist writes its own living doc (`docs/platform/`, `docs/security/`, `docs/data/`); SOLUTION.md keeps a 3-line summary + link per area.

## 7. Close
Update `.agent/context/ARCHITECTURE.md` (summary), ADRs, `modules.md` + arch test config; validate: `kit-run docs arch trace`.
Quality gate: interview answered (or assumptions listed) · style chosen by scored options + ADR · modules.md filled and enforced ·
project-structure.md filled · every hotspot has an algorithm + test approach · UI design system filled (if UI).
Summarise: decision, why, cost envelope, top risks, hand-offs created, ADRs needing approval. Next: kit-plan.
