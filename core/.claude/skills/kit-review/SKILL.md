---
name: kit-review
description: Code review of the current task diff against .agent/checklists/code-review.md and conventions, producing severity-labelled findings and fixing BLOCKER/MAJOR. Use before kit-task finish or when asked to review code.
---
# kit-review

1. Diff scope: `git diff --stat kit/TASK-NNN/base...HEAD` then review file by file (or delegate to `code-reviewer` sub-agent with the diff).
2. Check against `.agent/checklists/code-review.md`, `CONVENTIONS.md`, module rules in `ARCHITECTURE.md`, and the task's AC.
3. Output findings: `[BLOCKER|MAJOR|MINOR|NIT] file:line — problem — suggested fix`.
4. Fix BLOCKER + MAJOR now (checkpoint after), create follow-up tasks for out-of-scope MINOR items, ignore NITs the linter doesn't flag.
5. Record the review summary (counts per severity, what was fixed) in the task *Progress log*.
