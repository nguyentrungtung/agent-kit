# Coding conventions — summary
<!-- One line per rule that matters, with the tool that enforces it. Full rules + rationale live in .agent/rules/. -->
<!-- kit-onboard fills "Observed in code" with what the codebase ACTUALLY does where it differs from the standard. -->

| Area | Rule | Source | Enforced by |
|---|---|---|---|
| Formatting | Community formatter of each stack, config in repo is law | `.agent/rules/stack/*.md` | `kit-run format_check` (pre-push, CI) |
| Lint / static analysis | Zero new warnings | `.agent/rules/stack/*.md` | `kit-run lint`, `kit-run typecheck` |
| Architecture | Layer/module boundaries | `.agent/rules/project/`, `docs/architecture/` | `kit-run arch` (ArchUnit / deptrac / dependency-cruiser / import-linter / NetArchTest) |
| Errors | No swallowed exceptions, Problem Details on HTTP | `.agent/rules/core/error-handling.md` | review, lint |
| Logging | Structured, no secrets/PII | `.agent/rules/core/logging.md` | security review |
| Tests | Every AC + every bug fix has a test | `.agent/rules/core/testing.md` | CI, coverage ≥ `coverage_min` |
| Security | OWASP baseline, no secrets in repo | `.agent/rules/core/security.md` | secrets scan, semgrep, trivy, audit |
| Database | Versioned, backward-compatible migrations | `.agent/rules/core/database.md` | review, migration tool |
| Commits & branches | Conventional Commits, `<type>/TASK-NNN-slug` | `.agent/rules/core/git-workflow.md` | commit-msg hook, CI guard |

## Observed in code (differences from the standard)
TODO — filled by kit-onboard.
