---
name: kit-parallel
description: Orchestrate multiple agents in parallel (read-only sharded explore/review and write-isolated worktree swarms) without file conflicts or context bloat. Use when a goal spans multiple independent tasks, modules, or large diffs.
---
# kit-parallel — safe parallel agent orchestration

## 1. When to parallelize vs stay single-agent
- **Parallelize:** independent vertical tasks (`kit-board --ready --json`), multi-module codebase exploration, large diffs (`> 10` files or cross-layer review), independent test suites/shards.
- **Stay sequential:** Size S changes (`1–2` files), tasks coupled by `depends_on`, or tasks that must edit the same shared core files (`kit`, DB schema, shared configs).

## 2. Four invariants (no merge conflicts or blind spots)
1. **Isolate writers:** Read-only workers (`explore`, `review`, `audit`) may share the main working tree (`inherit`). **Writers** must work in separate branches/worktrees (`kit-task start TASK-NNN --worktree` → `../<repo>-TASK-NNN`, or isolated agent workspaces).
2. **File Ownership Matrix first:** Before launching writers, assign disjoint target files/directories per worker. If two ready tasks must edit the same file, link one via `depends_on` and run them sequentially.
3. **Structured, bounded output:** Require each worker to return a compact result (severity findings `[BLOCKER|MAJOR|MINOR|NIT]`, file paths with line numbers, or checkpoint SHA) — never whole-file dumps.
4. **Per-task PR & Coordinator integration:** Workers run per-task `kit-run check`, `kit-task checkpoint`, `kit-task verify`, and `kit-task finish` on their own task branch/worktree (one PR per task). The coordinator sequences PR merges onto `develop`, rebases remaining task branches if needed, runs final integration checks, and runs `kit-task merged TASK-NNN` + `kit-task cleanup TASK-NNN` from the main checkout after merge.

## 3. Parallel workflow
1. Find runnable work:
   ```bash
   .agent/scripts/kit-board --ready --json
   ```
2. Check overlap: confirm candidate `TASK-NNN` slices touch disjoint modules/files (and obey `.agent/rules/project/modules.md` when present, e.g. with module `sa`).
3. Provision worktrees for writers:
   ```bash
   .agent/scripts/kit-task start TASK-007 --worktree
   .agent/scripts/kit-task start TASK-008 --worktree
   ```
4. Launch workers (map to your active harness):
   - **Antigravity:** `run_workflow` (`parallel(items, fn)`) or parallel `invoke_subagent` calls (`Workspace: "share"|"branch"` for writers, `"inherit"` with fast tier `Model: "flash"` for read-only survey), or `/teamwork`.
   - **Claude Code:** parallel sub-agents (`explorer`, `code-reviewer`, `security-reviewer`) for read-only shards; separate sessions in each `--worktree` for writers.
   - **Codex / Gemini CLI / others:** separate sessions per worktree (`../<repo>-TASK-NNN`), monitoring progress from `.agent/scripts/kit-board`.
5. Verify & close: each task runs `kit-task verify` and `kit-task finish` on its own task branch; once PRs merge into `develop`, run `kit-task merged TASK-NNN` and `kit-task cleanup TASK-NNN` from the main checkout.
