# Roles, ownership and hand-offs

Each role is a playbook (skill) + a sub-agent with limited write scope + its own rules and living docs.
A role never silently does another role's job — it hands off (and the hand-off is written down).

| Role | Playbook / agent | Owns (living docs) | Module |
|---|---|---|---|
| Business analyst | `kit-ba` / ba-analyst | `docs/ba/` (requirements, user flows, UI wireframes & 4 states: empty/loading/error/success) | ba |
| Solution architect (integrator) | `kit-sa` / solution-architect | `docs/architecture/SOLUTION.md` (incl. interview, patterns & algorithms), options, ADRs, `project-structure.md`, `ui-design-system.md`, `.agent/rules/project/modules.md` | sa |
| DevOps / platform | `kit-devops`, `kit-docker` / devops-engineer | `docs/platform/`, Dockerfiles, compose, `infra/`, `deploy/`, workflows | devops |
| Application security | `kit-appsec` / security-architect (design) · `kit-security` / security-reviewer (per change) | `docs/security/` | security (+ core) |
| Data engineer | `kit-data` / data-engineer | `docs/data/`, pipelines, data contracts | data |
| Data analyst | `kit-da` | `dq/` (read-only SQL checks: correct / complete / fresh / clean — đúng, đủ, sống, sạch), `docs/data/quality/` (findings, reconciliation with sources) — gate: `kit-dq run`; with the Data engineer: `docs/data/catalog/` (`kit-catalog`: which table for which question, entities, metrics, filters) — gate: `kit-doc-coverage` | data |
| Planner | `kit-plan` / planner | `openspec/changes/`, tasks, `docs/plan/` | core + openspec |
| Full-stack Developer | `kit-task` | code (vertical slice: DB + logic + API + UI component), tests, living-doc updates in the same PR | core |
| QA | `kit-testcases` / qa-engineer | `docs/qa/` (Core 6 test matrix, incl. UI responsiveness & a11y) | core |
| Reviewer | `kit-review` / code-reviewer | review findings | core |

## Why Full-stack Developer (Vertical Slices) instead of separate FE / BE / Design roles?
To maximize AI velocity, avoid token explosion, and eliminate interface mismatch:
- **No separate FE/BE roles:** An agent implementing a vertical slice owns both the backend API and the frontend UI component for that slice. Contracts never drift, mock data isn't needed, and changes are verified end-to-end.
- **No separate Design role:** BA provides the wireframes & UI state requirements (WHAT to see); SA defines the Design System & tokens (HOW it looks & behaves); Full-stack Developer implements them directly.
- **Hats instead of roles:** when a task carries the tag `ui`, the Full-stack Developer also follows the UI checklist in `kit-task` §6b
  (design-system tokens, 4 states, a11y, generated API types). A new role is justified only when it owns living docs AND has its own gate.
- **Shared ground for BE + FE:** `docs/architecture/project-structure.md` (where every file goes), `.agent/rules/project/modules.md`
  (module ↔ feature, allowed dependencies), `docs/api/openapi.yaml` (the contract; FE types are generated from it).

## RACI for the main decisions (R responsible · A accountable · C consulted · I informed)
| Decision | BA | SA | DevOps | AppSec | Data | Full-stack Dev | Human lead |
|---|---|---|---|---|---|---|---|
| Scope, requirements, NFR numbers | R | C | C | C | C | I | A |
| Architecture style, boundaries, technologies | C | R | C | C | C | C | A |
| UI Wireframes, User Flows & Screen States | R | C | I | I | I | C | A |
| Frontend Architecture & Living Design System | C | R | I | C | I | C | A |
| Hosting, environments, CI/CD, SLOs, DR | I | C | R | C | I | I | A |
| Threat model, ASVS level, auth design, PII | C | C | C | R | C | I | A |
| Analytics architecture, pipelines, data contracts | C | C | C | C | R | I | A |
| Task breakdown and order | C | C | C | C | C | C | A (planner R) |
| Full-stack Vertical Slice Implementation (BE + FE) | I | C | I | I | I | R | A |
| Quality verification & Test matrix | C | C | I | C | I | C | A (QA R) |

## Hand-off flow
```
kit-ba ─▶ kit-sa ─┬─▶ kit-devops ─┐
                  ├─▶ kit-appsec ─┼─▶ kit-plan (OpenSpec changes + tasks) ─▶ kit-task …
                  └─▶ kit-data  ──┘
```
- The upstream role lists what it hands over (SOLUTION.md §6 hand-offs); the downstream role confirms or raises questions.
- Disagreement between roles → ADR with options; the human lead decides.
- Specialist findings that change scope or architecture go back upstream (to SA or BA), never patched silently downstream.
