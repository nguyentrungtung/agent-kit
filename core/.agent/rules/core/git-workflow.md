# Git workflow

- Gitflow: `main` (production) ← `release/*` ← `develop` ← `<type>/TASK-NNN-slug`. Hotfix: `hotfix/TASK-NNN-slug` from `main`.
- Branch types: `feature fix hotfix refactor chore docs test release revert`. One task = one branch = one PR.
- Commits: Conventional Commits `<type>(<scope>): <imperative subject>` ≤ 100 chars, body explains WHY, trailer `Refs: TASK-NNN`.
  Types: `feat fix chore docs style refactor perf test build ci revert sec`. Breaking change → `!` + `BREAKING CHANGE:` footer.
- Small commits that each build and pass tests (checkpoints). Formatting-only changes in their own commit.
- No merge commits on task branches from develop — rebase **before** the PR is opened; never rewrite pushed shared history.
- PR: fill the template, link the task, list how it was tested, screenshots for UI. CI must be green; at least one human approval.
- Enforced by: `commit-msg` hook, `pre-commit`/`pre-push`, Claude hooks, CI `guard` job, GitHub branch protection.
