# AGENTS.md — operating rules for AI coding agents

> Single source of truth for every agent (Claude Code, DeepSeek Harness, Codex, Cursor, …).
> Keep this file short. Details live in the files linked below and are read **on demand**.

## 0. Before anything
1. Run `.agent/scripts/kit-context` (Claude Code does this automatically at session start).
2. Read `.agent/memory/STATE.md` and, if on a task branch, the task file `.agent/tasks/TASK-NNN-*.md`.
3. If `.agent/context/PROJECT.md` still contains `TODO`, the project is not onboarded yet →
   follow the **kit-onboard** playbook before writing any code.

## 1. Where things are (read only what the task needs)
| Need | File |
|---|---|
| Goals, scope, users, non-goals | `.agent/context/PROJECT.md` |
| Architecture, modules, boundaries | `.agent/context/ARCHITECTURE.md` |
| **Rules** — core, per language/framework, project | `.agent/rules/` (`core/` · `stack/` · `project/`) — read the stack file before editing code |
| Coding conventions summary (rule → enforcing tool) | `.agent/context/CONVENTIONS.md` |
| Domain terms | `.agent/context/GLOSSARY.md` |
| Current status / where we left off | `.agent/memory/STATE.md` |
| Past decisions | `.agent/memory/DECISIONS.md` → `docs/adr/` |
| Mistakes not to repeat | `.agent/memory/LESSONS.md` |
| **Current behaviour (source of truth)** | `openspec/specs/` — read before changing anything |
| Changes in progress | `openspec/changes/<change>/` (proposal, spec deltas, design, tasks) |
| Requirements (BA) | `docs/ba/` · Architecture: `docs/architecture/` · API: `docs/api/` · Plan & roadmap: `docs/plan/` |
| Where each kind of document lives | `.agent/rules/core/documentation.md` · map: `docs/README.md` |
| Tasks | `.agent/tasks/` (one file per task) |
| Playbooks (step-by-step procedures) | `.claude/skills/<name>/SKILL.md` |
| Checklists | `.agent/checklists/` |
| Project commands | `.agent/project.yaml` (run them via `.agent/scripts/kit-run <step>`) |

## 2. Workflow (never skip a step) — details: `.agent/rules/core/workflow.md`
```
idea ─▶ kit-ba (UC/US/BR) ─▶ kit-sa (architecture, data) ─▶ kit-plan: OpenSpec change (proposal → specs → design → tasks) + kit tasks
     ─▶ per task: kit-task start ─▶ 1 understand ─▶ 2 clarify (ask!) ─▶ 3 solution ─▶ 4 tests first (red) ─▶ 5 implement + checkpoint
     ─▶ 6 verify ─▶ 7 document (living docs) ─▶ 8 kit-task finish (gates, archive change → specs, PR) ─▶ human merge
                     ▲                                  │
                     └──────── kit-task rollback ◀──────┘   (wrong direction? back to a restore point)
```
- **No code without a task. No task without acceptance criteria. Unclear → ask, never guess.**
- Everything traces to a use case: UC/US → change → TASK → test → code → spec.
- Work **only on a task branch** (`<type>/TASK-NNN-slug`). `main`, `develop`, `release/*`, `hotfix/*` are protected.
- Create documents with `.agent/scripts/kit-new <task|change|testplan|adr|usecase|story|doc>` — never invent the skeleton.
- Small steps: change → `kit-run check` → `kit-task checkpoint "<what is now working>"`. Same error 3× → rollback, LESSONS.md, re-plan.
- Done = `kit-task verify` passes + `.agent/checklists/definition-of-done.md`. Then `kit-task finish`.

## 3. Hard rules (also enforced by hooks / git hooks / CI)
- Never read, print, create or commit secrets: `.env*` (except `.env.example`), keys, certs, credentials, tokens.
  Need a new config value? Add the **name** to `.env.example` + document it; a human sets the value.
- Never bypass checks (`--no-verify`, disabling hooks, skipping tests, weakening lint rules, deleting failing tests).
- Never push to protected branches, force-push, or rewrite shared history. Rollback only via `kit-task`.
- No deploy / publish / infra / production-data commands — a human runs those.
- Do not edit guardrails: `.agent/hooks/`, `.githooks/`, `.claude/settings.json`, CI gates. Propose changes instead.
- Do not add dependencies without stating why in the task file; prefer the standard library / existing deps.
- Follow `.agent/rules/` (project > stack > core). If a formatter/linter/arch test disagrees with you, the tool wins.
- Local containers only through `kit-run up|down|logs`; deleting volumes/images needs a human.

## 4. Context discipline (keep sessions small)
- **One task per session.** Before the context gets large, or when the task is done: run **kit-handoff**, then start a new session (it will resume from `STATE.md` + the task file).
- Delegate wide reading to sub-agents (`explorer`, `qa-engineer`, `security-reviewer`, `code-reviewer`) and keep only their summaries.
- Prefer code-intelligence tools (codegraph / LSP / grep) over opening whole files. Read ranges, not files.
- **Parallel agents:** one task per agent per folder — `kit-task start TASK-NNN --worktree`, then a new session in `../<repo>-TASK-NNN`.
  Overview of all tasks: `.agent/scripts/kit-board` (also `--json` / `--html`).
- Write down anything a future session needs — in the task file's *Progress log*, `STATE.md`, `LESSONS.md` or an ADR — never rely on chat memory.

## 5. Documentation & reporting
- Docs language: see `docs_language` in `.agent/project.yaml`.
- End of every working session: `kit-daily` playbook → `docs/daily/<YYYY-MM>/<date>.md`.
- Every non-trivial decision (library, pattern, schema, trade-off) → `kit-adr` playbook → `docs/adr/NNNN-*.md`.

## 6. Playbooks
<!-- kit:playbooks:start (generated by kit init from installed skills) -->
<!-- kit:playbooks:end -->
Agents without native skills: open `.claude/skills/<name>/SKILL.md` and follow it literally.

## 7. Project-specific rules
<!-- Added by kit-onboard / humans. Keep ≤ 15 lines; move details to CONVENTIONS.md. -->
