---
name: kit-onboard
description: Onboard an EXISTING codebase into agent-kit — analyze the repo, fill PROJECT/ARCHITECTURE/CONVENTIONS/GLOSSARY, verify project commands, record a baseline. Use when .agent/context/PROJECT.md still has TODOs or the user says "onboard this project".
---
# kit-onboard — make an existing project agent-ready

Goal: after this, any fresh session can work correctly by reading `.agent/` only. Do NOT change product code here.

## Steps
1. **Branch:** `kit-task new "Onboard project into agent-kit" --type docs` → `kit-task start <id>`.
2. **Survey cheaply** (delegate to the `explorer` sub-agent if available; ask it for a ≤ 80-line summary):
   - README, build files, CI config, Dockerfiles, `.env.example`/config loaders, folder tree (depth 3), entry points, test layout.
   - Prefer installed code-intelligence / LSP tools (`kit-mcp status`) or `git ls-files | head` / grep over opening whole files. Never open `.env`.
3. **Fill context files** (in `docs_language`, concise, link to paths):
   - `.agent/context/PROJECT.md` — description, goals, users, constraints, current stage. Unknown business facts → write them under "Open questions", do not invent.
   - `.agent/context/ARCHITECTURE.md` — modules table with paths and allowed dependencies, data stores, integrations, mermaid diagram.
   - `.agent/context/CONVENTIONS.md` — fill "Observed in code": where the code differs from `.agent/rules/stack/*.md` (naming, layering, error/logging, tests).
   - `.agent/rules/project/` — module boundaries and domain rules found in code (one file per topic, each rule + enforcing tool).
   - `docs/GLOSSARY.md` — domain terms found in code.
3b. **Existing agent instructions or docs** (an own `AGENTS.md` / `AGENTS.md.kit-new`, `agent/`, `.cursor/`, an old `CLAUDE.md`, a `docs/` the
   `.gitignore` hides): run the **kit-migrate** playbook first (it starts from `.agent/scripts/kit-adopt-scan`), then come back here.
   Scan §8 lists checks the repo's CI / hooks run that no `cmd_*` covers — wire them in step 4.
4. **Wire the quality tools**: run `.agent/scripts/kit-doctor`. Merge every snippet in `.agent/stack/<stack>/snippets/`
   (e.g. Maven/Gradle plugins, ArchitectureTest with the real base package, tsconfig strict flags, Cargo lints) and adapt
   tool configs to the real folder layout (paths in phpstan/deptrac/dependency-cruiser…). Never relax a rule to get green — record debt instead.
   Format-only changes (`kit-run format`) go in ONE separate commit `style: apply <formatter>`.
   **The repo's own CI is the ground truth for commands.** Read `.gitlab-ci.yml` / `.github/workflows/*` / `.pre-commit-config.yaml` first and copy their exact
   commands into `cmd_*` (pinned tool versions, flags such as `--ignore=tests/live`, working directories). The kit's defaults stay only where the CI has nothing.
   A gate the repo does not use today (mypy, pip-audit, sqlfluff…) is not switched on silently: leave `cmd_*` empty and record it as baseline debt / an open question.
   Tests that call real APIs, queues or warehouses must be excluded from `cmd_test` (they need credentials) — never let `kit-run` or the pre-push hook run them.
   dbt: every `--target ci` command needs a `ci` target (DuckDB, see `.agent/stack/dbt/snippets/profiles.example.yml`); without it clear those `cmd_*` —
   `kit-doctor` flags this — so no command can reach a real warehouse.
   Verify commands in `.agent/project.yaml`: run each `kit-run <step>` (install, format_check, lint, typecheck, arch, test, build, audit).
   - Fix wrong commands (the user will be asked to approve edits to project.yaml). Missing tool → leave empty + note.
   - Record what fails today as **baseline debt** (don't fix it now).
5. **Baseline specs (if a spec plugin such as OpenSpec is installed):** for the 3–7 most important existing capabilities, write
   living specs describing CURRENT behaviour (verified against code/tests) and archive the baseline change in this task.
6. **Baseline report** → `docs/daily/<YYYY-MM>/<today>.md` via `kit-daily`, plus a "Baseline" section: test count/result, lint warnings count, audit findings, secrets scan result, top 5 risks/tech-debt items.
7. **Seed the backlog:** create tasks for the top risks (`kit-task new … --type chore|fix`), add them to `docs/plan/ROADMAP.md`.
8. **Project rules:** add ≤ 15 project-specific lines to AGENTS.md §7 (e.g. "all DB access through repository layer").
9. **Update `STATE.md`**, checkpoint, `kit-task finish`. Ask the human the open questions in one list.

## Done when
No `TODO` left in `.agent/context/*` (except explicit open questions), every `kit-run` step either passes or is documented as baseline debt.
