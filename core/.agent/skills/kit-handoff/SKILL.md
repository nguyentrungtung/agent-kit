---
name: kit-handoff
description: End a session cleanly so the next session (fresh, small context) can continue — checkpoint work, write handoff notes, update STATE.md and the daily report. Use when a task is done, before /clear, when context is getting large, or when the user ends the session.
---
# kit-handoff

1. `.agent/scripts/kit-task checkpoint "handoff: <state>"` (if there are changes and the code compiles; otherwise note "WIP broken at …").
2. Task file → **Handoff notes** (replace, ≤ 15 lines): exact next step (file/function), what is done/not done,
   failing tests and why, decisions made, gotchas, open questions.
3. `.agent/memory/STATE.md` → overwrite (≤ 40 lines): updated date, active task + branch, next up (ordered), open questions for the human, watch-outs.
4. New lessons → `.agent/memory/LESSONS.md`; new decisions → kit-adr.
5. Run the **kit-daily** playbook.
6. Commit memory/doc updates as part of the checkpoint (`kit-task checkpoint "handoff notes"`).
7. If the session hit repeated friction, record an enforceable rule in `.agent/rules/project/` and a 1-line lesson in `.agent/memory/LESSONS.md`.
8. Tell the human: "Safe to start a new session; it will resume from STATE.md + TASK-NNN."
