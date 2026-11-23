# CI/CD & releases

| Rule | Enforced by |
|---|---|
| Pipeline order: guard (secrets, branch, commits) → quality → security → build → deploy staging → smoke → approval → prod | workflow review |
| Required status checks + branch protection on main/develop; no direct pushes | GitHub settings, hooks |
| Actions pinned (tag or SHA); `permissions:` least privilege per job; no `pull_request_target` with checkout of untrusted code | actionlint, review |
| Never interpolate untrusted input (`github.event.*`, `head_ref`, titles) into `run:` — pass through `env:` | actionlint |
| Builds are reproducible: lockfiles committed, same artefact promoted across environments (build once, deploy many) | review |
| Versioning: semver tags; CHANGELOG from Conventional Commits | commit-msg hook, release checklist |
| Every deploy is reversible: previous artefact kept, DB migrations backward compatible, documented rollback | release checklist |
| Production deploy needs human approval (GitHub environment protection) | GitHub environments |
