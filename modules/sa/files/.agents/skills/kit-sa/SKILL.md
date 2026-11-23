---
name: kit-sa
description: Solution architecture — own the overall solution and integrate the specialist roles. Turn BA output and NFRs into quality scenarios, choose the architecture style (layered MVC + repository, HMVC/modular, modular monolith, hexagonal, microservices, event-driven) and technology with trade-offs, define module/service boundaries, integrations and the logical data model, write ADRs and docs/architecture/SOLUTION.md, then hand off platform to DevOps, security design to AppSec and analytics/pipelines to Data. Use when starting a project, before a large epic, or when asked "how should we architect this".
---
# kit-sa — solution architecture (integrator, not implementer)

You decide **what the system is made of and why**. Specialists decide **how it runs (DevOps), how it is protected (AppSec),
how data flows for analytics (Data)**. You advise; humans decide. Every significant choice is an ADR (`kit-new adr`).
Roles and hand-offs: `.agent/rules/core/roles.md`. Diagrams: kit-diagram. Write in `docs_language`.

## 1. Inputs
`docs/ba/` (goals, UC/US, BR, NFR numbers, volumes, integrations, and especially the **Architecture Hand-off Packet** in `docs/ba/BRIEF.md`),
`PROJECT.md` (constraints, budget, team skills, deadline), existing code via codegraph (`codegraph explore`) for brownfield, `.agent/rules/stack/*`.
Missing numbers → ONE batch (≤ 7) or `ASSUMPTION:`.

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

## 3b. Module design (with module eng-skills)
Use **mp-codebase-design** vocabulary (deep modules, small interfaces, seams) for module boundaries; on brownfield code run
**mp-improve-codebase-architecture** to find deepening opportunities before adding new structure. Terms → **mp-domain-modeling**.

## 4. Options per big decision → `docs/architecture/options/<topic>.md`
2–3 options with weighted criteria (scenario fit, complexity/team skill, cost envelope, lock-in, operability, risk) → recommendation → ADR.

## 5. Design → `docs/architecture/SOLUTION.md` (arc42-lite)
- C4 **Context** + **Container**; module/bounded-context map with allowed dependencies → `.agent/rules/project/modules.md` + the stack's arch test.
- **Integration**: API style, contracts (OpenAPI/AsyncAPI under docs/api/), sync vs async, idempotency, retries, timeouts.
- **Logical data model**: entities and ownership per module, consistency (transaction vs eventual + outbox), ID strategy (ADR) —
  detailed with the **kit-datamodel** playbook into `docs/architecture/data-model.md` (relationships, keys, constraints, migrations).
- **API contracts**: with module api, the **kit-api** playbook (contract-first `docs/api/openapi.yaml`).
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
Update `.agent/context/ARCHITECTURE.md` (summary), ADRs, project module rules; validate diagrams (`kit-run docs`).
Summarise: decision, why, cost envelope, top risks, hand-offs created, ADRs needing approval. Next: kit-plan.
