---
name: kit-sa
description: Solution architecture & infrastructure consulting — turn BA output and NFRs into 2–3 architecture options with trade-offs, pick one with an ADR, and document it arc42-lite in docs/architecture/ (C4 context/container/deployment diagrams, quality-attribute tactics, data & integration design, security zones, observability, infra sizing and cost, risks). Use when starting a project, before a big epic, or when asked "how should we architect / host / scale this".
---
# kit-sa — Solution Architecture

You advise; humans decide. Every significant choice ends as an ADR (`kit-adr`). Write in `docs_language`. Diagrams follow **kit-diagram**.

## 1. Inputs (read first)
`docs/ba/` (goals, FR, **NFR numbers**, volumes, integrations), `.agent/context/PROJECT.md` (constraints, budget, team skills),
`.agent/context/ARCHITECTURE.md` + code (existing system — use codegraph), `.agent/rules/stack/*` (chosen stacks).
Missing numbers (users, RPS, data growth, RTO/RPO, budget, compliance, hosting constraints) → ask ONE batch (≤ 7) or write `ASSUMPTION:`.

## 2. Architecturally significant requirements → `SOLUTION.md §2`
Turn NFRs into **quality-attribute scenarios** (source, stimulus, environment, response, measure), ranked. These drive every decision.

## 3. Options → `options/<topic>.md`
For each big decision (style: modular monolith vs services; sync vs async; DB; hosting: VPS/Kubernetes/PaaS/serverless; auth; cache; messaging):
2–3 realistic options, comparison table (fit to top scenarios, complexity, team skill, cost/month, lock-in, operability, risk), recommendation.
Bias: **simplest thing that meets the scenarios** — modular monolith + one relational DB unless numbers say otherwise.

## 4. Design → `docs/architecture/SOLUTION.md` (arc42-lite template)
- **C4 Context** (system + users + external systems) and **C4 Container** (apps, DBs, queues, caches, their tech and protocols).
- Module/bounded-context map with allowed dependencies → feed `.agent/rules/project/modules.md` and the stack's arch test (ArchUnit/deptrac/dependency-cruiser…).
- Key runtime scenarios as sequence diagrams (happy path + failure).
- Data: ownership per module, consistency (transactions vs eventual + outbox), retention, backup.
- Integration: API style, contracts (OpenAPI/AsyncAPI), idempotency, retries, timeouts.
- **Deployment** (C4 Deployment): environments (local/dev/staging/prod), network zones, scaling, CI/CD flow.
- Cross-cutting: authN/Z, secrets management, observability (logs/metrics/traces, SLOs), error handling, i18n, multitenancy.
- **Security zones & threat model** link (`docs/security/THREAT-MODEL.md`, STRIDE on the container diagram).
- **Sizing & cost** (`sizing.md`): estimate from volumes → CPU/RAM/storage/IOPS per container per env, monthly cost table, scaling triggers.
- Risks & technical debt, with mitigation.

## 5. Local runtime
If the project has no runnable local environment, hand off to **kit-docker** with the container list (DB, cache, queue, auth, observability).

## 6. Consistency
Update `.agent/context/ARCHITECTURE.md` (short summary + links), write ADRs for each decision, add project rules for boundaries.
Validate diagrams: `.agent/scripts/kit-run docs`. Summarise to the human: decision, why, cost, top risks, ADRs needing approval.
