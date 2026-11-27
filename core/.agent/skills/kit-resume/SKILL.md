---
name: kit-resume
description: Start or resume work in a fresh session with minimal context — load STATE.md, the active task and its handoff notes, verify the branch and tests. Use at the start of a session or when the user says "continue".
---
# kit-resume

1. `.agent/scripts/kit-context` (full pack) — or read `STATE.md` + task file if already injected at session start.
2. `.agent/scripts/kit-task status` — confirm branch = task branch; if on a protected branch, `kit-task start TASK-NNN` (resumes existing branch).
3. Read the task's **Handoff notes** and last 10 *Progress log* lines. Read only the files they point to.
4. Sanity check: `.agent/scripts/kit-run test` (or the narrowest relevant test) to know the starting state.
5. State in 3 lines: what you will do next, how you'll verify it, anything blocking. Then continue with kit-task §2.
