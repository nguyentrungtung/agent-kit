# Tasks
One file per task: `TASK-NNN-slug.md` (create with `.agent/scripts/kit-task new "<title>"`).
A task must fit in **one agent session** (~≤ 300 changed lines). Bigger → split in kit-plan.
Status flow: `todo → in-progress → review → done` (or `abandoned`). Board: `.agent/scripts/kit-board`.

## Front matter schema (stable — read by kit-board, kit-task sync-gh and any future UI)
| Key | Values | Set by |
|---|---|---|
| `id` | `TASK-NNN` | kit-task new |
| `title` | text | kit-task new |
| `status` | `todo` `in-progress` `review` `done` `abandoned` | kit-task start/finish, sync |
| `type` | `feature fix hotfix refactor chore docs test` | kit-task new |
| `priority` | `P1` `P2` `P3` | kit-task new / kit-plan |
| `goal_ref` | `G1`… (PROJECT.md goal) | kit-plan |
| `depends_on` | `[TASK-001, …]` | kit-plan |
| `assignee` | agent/session or person | human / orchestrator |
| `branch` | `<type>/TASK-NNN-slug` | kit-task start |
| `worktree` | path relative to repo root, e.g. `../app-TASK-007` | kit-task start --worktree |
| `issue` | GitHub issue number (pull-gh). Links made by `sync-gh` live in `.agent/tasks/.issues` (`TASK-NNN=<n>`) so task branches never conflict | kit-task sync-gh / pull-gh |
| `created` `started` `done` | `YYYY-MM-DD` | kit-task |

The *effective* status shown on the board is read from the task's own branch (where `start` / `finish` record it);
a `review` task whose branch is merged into develop/main is shown as `done`.
