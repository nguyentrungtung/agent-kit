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
7. Tell the human: "Safe to start a new session; it will resume from STATE.md + TASK-NNN."

## Retro (optional, with module eng-skills)
When the session hit friction, run **mp-retro**: it proposes environment fixes (navigation pointers, automated checks, rules).
Mechanical rules become checks (lint/arch test/hook); judgement calls go to `.agent/rules/project/`; record the lesson in LESSONS.md.
