---
name: kit-migrate
description: Move an EXISTING repo's own agent rules and docs into the agent-kit layout without losing anything — old AGENTS.md / agent/ / .cursor rules into .agent/, docs/ indexed, .kit-new merged, CI merged, then the old copies removed. Use right after kit init on a repo that already had agent instructions or docs, or when kit-adopt-scan lists old files.
---
# kit-migrate — bring an existing repo's rules and docs into the kit (nothing lost, nothing twice)

Goal: ONE set of rules (`AGENTS.md` + `.agent/`) that every agent and teammate reads, docs the kit can find, and no old copy left
behind. Do NOT change product code here. Run it before `kit-onboard` (which then fills the context files from code).

## 0. Inventory (no guessing)
1. `kit-task new "Migrate agent rules and docs into agent-kit" --type docs` → `kit-task start <id>`.
2. Run `.agent/scripts/kit-adopt-scan` and work from its report (`.agent/local/adopt-scan.md`), section by section. Re-run it after
   each step; the playbook is done when sections 1, 2, 5, 6 and 7 say "None" / ✓ (or list only what the human chose to keep).

## 1. Ask the human ONE question first — then wait
"Are the agent rules and `docs/` shared with the team (committed) or kept on your machine only?"
- **Shared** (default for a team repo): §4 of the scan must be clean before any `.gitignore` line is removed.
- **Personal**: keep `.gitignore` as it is, but then `CLAUDE.md`, `.agent/` and `.agents/` must be ignored too (add them) — a
  committed `CLAUDE.md` that imports an ignored `AGENTS.md` gives teammates no rules at all. Skip step 5.
Record the answer in `.agent/memory/DECISIONS.md`.

## 2. Rules: move, merge, shorten (scan §1)
Map every old file by **content**, not by name. One topic lives in one place:
| Old content | Goes to |
|---|---|
| What the project is, sources, stakeholders, stage | `.agent/context/PROJECT.md` |
| Layers, modules, data flow, stores | `.agent/context/ARCHITECTURE.md` (+ `docs/architecture/SOLUTION.md` for the long form) |
| Naming, style, conventions observed in code | `.agent/context/CONVENTIONS.md`; enforceable ones → `.agent/rules/project/<topic>.md` |
| Security rules (secrets, PII, network) | `.agent/rules/project/security.md` |
| Data rules (layers, naming, contracts, idempotency) | `.agent/rules/project/data.md` |
| Code skeletons / templates | `.agent/stack/<stack>/skeletons/` (used by `kit-new module`) |
| Domain terms | `GLOSSARY.md` |
| Gotchas, incidents, "we learned that…" | `.agent/memory/LESSONS.md` (short) — long write-ups stay in `docs/` and are linked |
| Runbooks, how-to-operate | `docs/platform/runbooks/` (or keep where they are and link) |
| Constitution / principles duplicating `.agent/rules/core/*` | **drop the duplicate**; keep only what differs, as a project rule |
- Before writing a rule, check `.agent/rules/core/` and `.agent/rules/stack/`: never paste a rule the kit already has. Project rules win
  over kit rules, so a real conflict goes to `.agent/rules/project/` with one line saying which kit rule it overrides.
- `AGENTS.md`: start from `AGENTS.md.kit-new` (the kit's structure) and put the project's own top rules in **§7 (≤ 30 lines)**; everything
  longer becomes a linked file above. Agents load AGENTS.md every session — a 400-line AGENTS.md costs every task.
- `CLAUDE.md` = `@AGENTS.md` only. `GEMINI.md`, `.cursorrules`, `.cursor/rules/`, `copilot-instructions.md`: replace their content with a pointer
  to AGENTS.md (or delete them when the harness reads AGENTS.md natively).
- Keep a move log in the task file: `old path → new path (what was dropped and why)`.

## 3. Links (scan §2)
Every reference to an old path must point to its new place before the old file goes. Fix them in docs too. Re-run the scan: §2 = None.

## 4. Docs (scan §3)
- Do NOT rename or re-shelve existing docs folders in bulk — links, bookmarks and people depend on them. Keep them; make `docs/README.md`
  the map: merge `docs/README.md.kit-new` into the existing index (kit slots table + your folders, one line each).
- Copy into the kit slots only what agents must read: architecture → `docs/architecture/SOLUTION.md`, data sources → `docs/data/`,
  current behaviour → `openspec/specs/` (via `kit-onboard` step 5). Link to the original instead of duplicating long documents.
- Binary/heavy files (xlsx, docx, Postman exports): committed only if the team needs them and §4 says they are clean; otherwise keep them
  out of Git and say where they live.

## 5. Before sharing (scan §4) — only when the answer in step 1 was "shared"
- Every item must be resolved: remove the value (keep the name, point to `.env.example`), redact the export, or keep that file ignored
  (add a precise line such as `docs/reference/**/*.postman_collection.json` — never re-ignore the whole folder).
- Then delete the `.gitignore` lines of scan §5 that hide kit files, AGENTS.md and docs/. Run `.agent/scripts/kit-secrets-scan --all`
  and `git status` — read the list of newly visible files before staging anything.

## 6. Merge what the kit left next to your files (scan §6, §7)
- Each `X.kit-new` → merge into `X`, delete the `.kit-new`. `*.bak-kit` → delete once the merged settings work.
- CI: include the kit's pipeline (`include: [{ local: .gitlab-ci.kit.yml }]`) or merge its jobs, then remove jobs that now run twice. The
  repo's own checks (scan §8) go into the matching `cmd_*` in `.agent/project.yaml` (usually `cmd_lint`) — the human approves that edit.

## 7. Remove the old copies — last
Only when §2 is None and every old file is in the move log: delete `agent/` (and the other old rule folders), then re-run the scan and
`.agent/scripts/kit-doctor`. One commit per step (`docs(agent): move security rules into .agent/rules/project`, …) so each is reviewable.

## Done when
Scan §1, §2, §5, §6, §7 are empty (or hold only what the human decided to keep), `kit-doctor` has no ✗ about ignored kit files or hooks,
the move log is in the task file. Then `kit-task finish` and continue with **kit-onboard**.
