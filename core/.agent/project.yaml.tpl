# agent-kit project config — flat "key: value" (no nesting). Read by .agent/scripts/* and hooks.
name: {{NAME}}
description: {{DESCRIPTION}}
stack: {{STACK}}                # primary stack
components: {{COMPONENTS}}      # path=stack[+framework] … (kit init)
modules: {{MODULES}}
arch_style: modular         # layered | modular — decided by an ADR (kit-sa); used by kit-new module
base_package:               # Java/Kotlin base package, e.g. com.example.shop (kit-new module)
docs_language: vi            # language the agent writes docs/reports in (vi | en)
kit_version: {{KIT_VERSION}}

# --- Branching (gitflow) ---
main_branch: main            # production
develop_branch: develop      # integration + UAT (gitflow); set to "main" for trunk-based
staging_branch:              # optional long-lived pre-production branch (e.g. staging); empty = release/* is what STAGING runs
branch_types: feature feat bugfix fix hotfix release support refactor chore docs test ci perf build style revert
branch_max_len: 60           # <type>/<TASK-NNN>-<kebab-case-description>, checked by CI (kit-ci guard) and pre-push
gitflow_enforce: block       # block = CI fails on a bad branch name / merge direction · warn = CI only warns
branch_exempt_regex: ^(dependabot/|renovate/|snyk-|revert-[0-9]+-|gh-readonly-queue/)   # tool-made branches, never checked
protected_extra: master release/* hotfix/*
protected_regex: ^(main|master|develop|release/.*|hotfix/.*)$
push_checkpoints: true       # push task branch to origin on every checkpoint (remote backup)

# --- Tasks & Git hosting ---
gitlab_url:                  # GitLab only, optional: https://gitlab.example.com (empty = taken from the git remote)
gitlab_project:              # GitLab only, optional: group/subgroup/project (empty = taken from the git remote)
git_provider:                # github | gitlab — where PRs/MRs are opened (empty = guess from the remote URL; set it for self-hosted GitLab)
gh_project:                  # optional GitHub Project for kit-task sync, as <owner>/<number> (e.g. @me/3 or my-org/7)

# --- Commands (verified by the kit-onboard playbook; empty = skipped) ---
# Steps: install format format_check lint typecheck arch test build audit docs up down logs
# Multi-component repos: each cmd runs per component as (cd <path> && …) joined with &&.
{{COMMANDS}}
cmd_dup: npx -y jscpd@4.0.5 --config .jscpd.json .
cmd_lint_staged:             # optional fast lint for pre-commit (e.g. lint-staged, ruff on changed files)

# --- Gates ---
prepush_checks: lint test    # kit-run steps executed by the pre-push hook
stop_checks: format_check lint test_fast   # Claude Code Stop hook: fast gates on uncommitted code before the agent ends a turn (none = off; empty cmd_test_fast = skipped)
stop_repeat_max: 3           # the same stop-gate failure this many turns in a row → stop patching: rollback or ask the human, write LESSONS.md
max_file_kb: 2048
commit_types: feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert|sec
commit_subject_max: 100
coverage_min: 70             # target used by the QA playbook / CI (enforce in your test tool config)

# --- Secrets / safety (perl regex) ---
secrets_forbidden_extra:
secrets_ignore_paths: (^|/)(docs/|.*test.*fixtures?/|.*\.lock$|package-lock\.json$)
ask_commands_extra:          # e.g. \bmake\s+deploy\b|\bansible-playbook\b
