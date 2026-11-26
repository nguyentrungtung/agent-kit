# Roles, ownership and hand-offs

Each role is a playbook (skill) + optional sub-agent with focused scope. Core roles are always installed; specialist module roles apply when their plugin is enabled (`.agent/plugins/`).
A role never silently does another role's job — it hands off in writing.

| Role | Playbook / agent | Owns (living docs) | Source |
|---|---|---|---|
| Full-stack Developer | `kit-task` | code (vertical slice: DB + logic + API + UI), tests, living docs in same PR | core |
| Planner | `kit-plan` / planner | task breakdown, `docs/plan/` (+ active spec changes when enabled) | core |
| QA | `kit-testcases` / qa-engineer | `docs/qa/` (Core 6 test matrix, UI responsiveness & a11y) | core |
| Reviewer | `kit-review` / code-reviewer | review findings (`kit-task review`) | core |
| Security Reviewer | `kit-security` / security-reviewer | diff security review (+ `docs/security/` when `security` plugin enabled) | core |
| Specialist modules (when enabled) | `kit-ba`, `kit-sa`, `kit-devops`, `kit-appsec`, `kit-data` / `kit-da` | `docs/ba/`, `docs/architecture/`, `docs/platform/`, `docs/security/`, `docs/data/` | optional plugins |

## Why Full-stack Developer (Vertical Slices) instead of separate FE / BE / Design roles?
To maximize AI velocity, avoid token explosion, and eliminate interface mismatch:
- **No separate FE/BE roles:** An agent implementing a vertical slice owns both the backend API and the frontend UI component for that slice. Contracts never drift, mock data isn't needed, and changes are verified end-to-end.
- **No separate Design role:** BA provides the wireframes & UI state requirements (WHAT to see); SA defines the Design System & tokens (HOW it looks & behaves); Full-stack Developer implements them directly.
- **Hats instead of roles:** when a task carries the tag `ui`, the Full-stack Developer also follows the UI checklist in `kit-task` §6b
  (design-system tokens, 4 states, a11y, generated API types). A new role is justified only when it owns living docs AND has its own gate.
- **Shared ground for BE + FE:** `docs/architecture/project-structure.md` (where every file goes, when `sa` enabled), `.agent/rules/project/modules.md`
  (module ↔ feature, allowed dependencies), `docs/api/openapi.yaml` (the contract; FE types generated from it when `api` enabled).

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

## Hand-off flow (active plugins + core)
```
kit-ba ─▶ kit-sa ─┬─▶ kit-devops ─┐
                  ├─▶ kit-appsec ─┼─▶ kit-plan (changes + tasks) ─▶ kit-task …
                  └─▶ kit-data  ──┘
```
- When specialist plugins are enabled, the upstream role lists what it hands over (e.g. `SOLUTION.md §6` hand-offs); the downstream role confirms or raises questions.
- Disagreement between roles → ADR with options; the human lead decides.
- Specialist findings that change scope or architecture go back upstream (to SA or BA), never patched silently downstream.
