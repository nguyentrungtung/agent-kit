# Roles, ownership and hand-offs

Each role is a playbook (skill) + a sub-agent with limited write scope + its own rules and living docs.
A role never silently does another role's job — it hands off (and the hand-off is written down).

| Role | Playbook / agent | Owns (living docs) | Module |
|---|---|---|---|
| Business analyst | `kit-ba` / ba-analyst | `docs/ba/` | ba |
| Solution architect (integrator) | `kit-sa` / solution-architect | `docs/architecture/SOLUTION.md`, options, ADRs | sa |
| DevOps / platform | `kit-devops`, `kit-docker` / devops-engineer | `docs/platform/`, Dockerfiles, compose, `infra/`, `deploy/`, workflows | devops |
| Application security | `kit-appsec` / security-architect (design) · `kit-security` / security-reviewer (per change) | `docs/security/` | security (+ core) |
| Data engineer | `kit-data` / data-engineer | `docs/data/`, pipelines, data contracts | data |
| Planner | `kit-plan` / planner | `openspec/changes/`, tasks, `docs/plan/` | core + openspec |
| Developer | `kit-task` | code, tests, living-doc updates in the same PR | core |
| QA | `kit-testcases` / qa-engineer | `docs/qa/` | core |
| Reviewer | `kit-review` / code-reviewer | review findings | core |

## RACI for the main decisions (R responsible · A accountable · C consulted · I informed)
| Decision | BA | SA | DevOps | AppSec | Data | Human lead |
|---|---|---|---|---|---|---|
| Scope, requirements, NFR numbers | R | C | C | C | C | A |
| Architecture style, boundaries, technologies | C | R | C | C | C | A |
| Hosting, environments, CI/CD, SLOs, DR | I | C | R | C | I | A |
| Threat model, ASVS level, auth design, PII | C | C | C | R | C | A |
| Analytics architecture, pipelines, data contracts | C | C | C | C | R | A |
| Task breakdown and order | C | C | C | C | C | A (planner R) |

## Hand-off flow
```
kit-ba ─▶ kit-sa ─┬─▶ kit-devops ─┐
                  ├─▶ kit-appsec ─┼─▶ kit-plan (OpenSpec changes + tasks) ─▶ kit-task …
                  └─▶ kit-data  ──┘
```
- The upstream role lists what it hands over (SOLUTION.md §6 hand-offs); the downstream role confirms or raises questions.
- Disagreement between roles → ADR with options; the human lead decides.
- Specialist findings that change scope or architecture go back upstream (to SA or BA), never patched silently downstream.
