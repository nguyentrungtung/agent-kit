---
name: kit-rollback
description: Safely undo agent work — roll back the current task to a checkpoint/base, abandon a task, or revert an already-merged task via a revert PR. Use when the implementation went the wrong way, tests broke badly, or a merged change must be undone.
---
# kit-rollback

All rollbacks keep a backup branch — nothing is lost. Raw `git reset --hard` / force push are blocked on purpose.

| Situation | Command |
|---|---|
| See restore points | `.agent/scripts/kit-task points` |
| Last step was wrong (discard since latest checkpoint) | `.agent/scripts/kit-task rollback` |
| Go back to a specific point | `.agent/scripts/kit-task rollback --to cp-3` |
| Whole approach wrong, restart the task | `.agent/scripts/kit-task rollback --to base` |
| Drop the task entirely | `.agent/scripts/kit-task abandon` |
| Already merged into develop | `.agent/scripts/kit-task merged TASK-NNN` (if not tagged yet) → `.agent/scripts/kit-task revert TASK-NNN` → push branch + PR |

After any rollback:
1. Write why in the task *Progress log* and one line in `.agent/memory/LESSONS.md` (`- date [area] what failed → do instead`).
2. Re-plan the remaining steps in the task file before coding again.
3. Tell the human which backup branch holds the discarded work.
