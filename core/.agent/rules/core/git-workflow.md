# Git workflow — gitflow (community git-flow + Conventional Branch / Conventional Commits)

`main_branch` / `develop_branch` / `staging_branch` in `.agent/project.yaml` (trunk-based: `develop_branch: main`, then every task merges into main).
The rules below are checked by `.agent/scripts/kit-ci guard` (CI, blocking) and the pre-push hook (warning) — one definition in `lib.sh`.

## Branches and environments
| Branch | Lives | Branches from → merges into | Deployed to | Who merges |
|---|---|---|---|---|
| `main` (or `master`) | forever | ← `release/*`, `hotfix/*` only — **go-live only**, every merge tagged `vX.Y.Z` | **PRODUCTION** | human, after UAT sign-off |
| `develop` | forever | ← every task branch; back-merges from `main` | **DEV / UAT** (integration: features are tested together here) | human, PR + green CI |
| `staging` (optional, `staging_branch`) | forever | ← `develop`, `release/*`, `hotfix/*` | **STAGING** (pre-production) | human |
| `release/vX.Y.Z` | until released | from `develop` → `main` (tag) **and back into** `develop` | **STAGING** (release candidate) — only fixes from now on | human |
| `hotfix/<TASK-NNN>-<desc>` or `hotfix/vX.Y.Z` | hours | from `main` → `main` (tag, patch) **and back into** `develop` | STAGING check, then PRODUCTION | human |
| `feature/` (`feat/`) | days | from `develop` → `develop` | DEV / UAT once merged | PR |
| `bugfix/` (`fix/`) | days | from `develop` → `develop` (a bug found on develop / UAT, not in production) | DEV / UAT | PR |
| `refactor/ chore/ docs/ test/ ci/ perf/ build/ style/ revert/` | days | from `develop` → `develop` | — | PR |
| `support/vX.Y` | long | from a tag, for an old major still maintained | — | human |

Never commit or push to `main`, `develop`, `staging`, `release/*`, `hotfix/*` directly (hooks block it): everything goes through a PR/MR.
A production bug is a **hotfix** (from main); a bug found while testing develop/UAT is a **bugfix** (from develop).

## Branch names
`<type>/<TASK-NNN>-<short-description>` — e.g. `feature/TASK-042-export-csv`, `bugfix/TASK-051-null-ngay-tiep-nhan`, `hotfix/v1.4.1`,
`release/v1.5.0`.
- type: one of `branch_types` (default `feature feat bugfix fix hotfix release support refactor chore docs test ci perf build style revert`).
- description: lowercase kebab-case `a-z 0-9 -` (no spaces, underscores, accents or capitals), led by the kit task id `TASK-NNN` on
  code branches (feature/bugfix/fix/hotfix/refactor — the CI task gates read it; an external issue key goes in the task file, not the
  name); it may end in a version (`chore/back-merge-v1.2.0`); release/hotfix/support may be just a version. At most `branch_max_len` (60).
- Branches made by tools are not checked: `branch_exempt_regex` (Dependabot, Renovate, Snyk, GitHub's revert button `revert-123-…`,
  merge queues).
- `gitflow_enforce: block` (new projects) fails CI on a wrong name or merge direction; `warn` (projects upgraded from < 0.14) only warns —
  switch to `block` once the open branches follow the convention (renaming a pushed branch closes its open PR: rename before opening one).
- `kit-task start` creates the right name and base for the task's type (`--type feature|bugfix|hotfix|refactor|chore|docs|test|ci|perf`).

## Commits and PRs
- Conventional Commits `<type>(<scope>): <imperative subject>` ≤ 100 chars, body explains WHY, trailer `Refs: TASK-NNN`.
  Types: `feat fix chore docs style refactor perf test build ci revert sec`. Breaking change → `!` + `BREAKING CHANGE:` footer.
- Small commits that each build and pass tests (checkpoints). Formatting-only changes in their own commit.
- Rebase the task branch on `develop` **before** opening the PR; never rewrite pushed shared history; no merge commits from develop into a task branch.
- PR/MR: one task = one branch = one PR into `develop` (hotfix → `main`), template filled, task linked, how it was tested, screenshots for UI.
  CI green + at least one human approval. Task branches: squash or merge commit (team choice, keep it consistent); release/hotfix into
  main: merge commit (`--no-ff`) so the release is one visible point, then the tag.

## Release (develop → UAT → staging → production)
1. Features merged into `develop` are tested together on DEV/UAT.
2. `kit-release prepare` cuts `release/vX.Y.Z` from develop (semver from the commits, CHANGELOG, version bump) → deploy to STAGING;
   only fixes land on the release branch.
3. UAT / business sign-off on staging → PR `release/vX.Y.Z` → `main`; after merge `kit-release tag` (tag `vX.Y.Z`), deploy to PRODUCTION.
4. Back-merge `main` into `develop` (PR) so the release fixes are not lost.
Hotfix: `hotfix/…` from main → PR into main → tag (patch) → back-merge into develop (and into an open `release/*`).

## Enforced by
`commit-msg` hook (Conventional Commits), `pre-commit` / `pre-push` (protected branches, secrets, branch-name warning, checks),
Claude Code hooks, CI `kit-ci guard` (branch name, merge direction, commits, secrets), branch protection on the Git host
(protect `main`, `develop`, `staging`, `release/*`; require PR + green CI).
