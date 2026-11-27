---
name: kit-review
description: Code review of the current task diff against .agent/checklists/code-review.md and conventions, producing severity-labelled findings and fixing BLOCKER/MAJOR. Use before kit-task finish or when asked to review code.
---
# kit-review

1. Diff scope: `git diff --stat kit/TASK-NNN/base...HEAD` then review file by file (or delegate to `code-reviewer` sub-agent with the diff).
   - **Large diffs (`> 10` files or multiple layers):** shard the review across parallel fresh-context reviewers by module/directory or lens (*Correctness/Logic* · *Change Safety/Upgrades* · *Security/Hooks* · *Docs/Traceability*), then deduplicate findings into one combined summary (see `kit-parallel`).
2. Check against `.agent/checklists/code-review.md`, `CONVENTIONS.md`, module rules in `ARCHITECTURE.md`, and the task's AC.
3. Output findings: `[BLOCKER|MAJOR|MINOR|NIT] file:line — problem — suggested fix`.
4. Fix BLOCKER + MAJOR now (checkpoint after), create follow-up tasks for out-of-scope MINOR items, ignore NITs the linter doesn't flag.
5. Record it: `.agent/scripts/kit-task review "BLOCKER 0 · MAJOR 1 fixed · MINOR 2 → TASK-031 — by <reviewer>"`.
   `kit-task verify` (and CI) block when no review is recorded or the latest one has a BLOCKER/MAJOR marked `open`.
   Re-review after fixing BLOCKER/MAJOR when the fix was large, and record the new line (newest wins).

## Why review locally when the PR also gets an external reviewer
The author's model has the author's blind spots. Run the review in a fresh context (the `code-reviewer` sub-agent, or an active review plugin skill), never "re-read my own diff" in the same session, and include the checklist sections on upgrades, parsing
edge cases and gate scope. Local review is cheap and runs before push; the PR reviewer should find little.
