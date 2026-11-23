# Tasks
One file per task: `TASK-NNN-slug.md` (create with `.agent/scripts/kit-task new "<title>"`).
Status flow: `todo → in-progress → review → done` (or `abandoned`). Board: `.agent/scripts/kit-board`.

## Sizing & Execution Discipline (Sweet Spot)
To maximize AI velocity while keeping context small and safe:
- **Do NOT create micro-tasks** (e.g. separate tasks for Entity, DTO, Service, Controller).
- **Size M is the sweet spot** (~150–350 changed lines): 1 complete vertical slice (schema + logic + API/UI + tests).
- **Use internal checkpoints**: Within a Size M task, run `kit-task checkpoint "<step>"` at each green milestone instead of creating new tasks. Run `kit-task finish` once when all ACs are satisfied.
- **Size L (> 350 lines)**: Too large for a single context session; split into smaller vertical slices in `kit-plan`.
- **Parallel work**: Independent tasks run concurrently via `kit-task start TASK-NNN --worktree`.

## Front matter schema (stable — read by kit-board, kit-task sync-gh and any future UI)
| Key | Values | Set by |
|---|---|---|
| `id` | `TASK-NNN` | kit-task new |
| `title` | text | kit-task new |
| `status` | `todo` `in-progress` `review` `done` `abandoned` | kit-task start/finish, sync |
| `type` | `feature fix hotfix refactor chore docs test` | kit-task new |
| `priority` | `P1` `P2` `P3` | kit-task new / kit-plan |
| `tags` | `[topic1, topic2]` e.g. `[auth, api]` | kit-task new --tags "auth, api" |
| `goal_ref` | `G1`… (PROJECT.md goal) | kit-plan |
| `depends_on` | `[TASK-001, …]` | kit-plan |
| `assignee` | agent/session or person | human / orchestrator |
| `branch` | `<type>/TASK-NNN-slug` | kit-task start |
| `worktree` | path relative to repo root, e.g. `../app-TASK-007` | kit-task start --worktree |
| `issue` | GitHub issue number (pull-gh). Links made by `sync-gh` live in `.agent/tasks/.issues` (`TASK-NNN=<n>`) so task branches never conflict | kit-task sync-gh / pull-gh |
| `created` `started` `done` | `YYYY-MM-DD` | kit-task |

The *effective* status shown on the board is read from the task's own branch (where `start` / `finish` record it);
a `review` task whose branch is merged into develop/main is shown as `done`.

## Topic-based Long-Term Memory (Zero Dependencies)
Tasks can be tagged with domain topics (`--tags "auth, api"`).
When starting a task (`kit-task start TASK-NNN`), relevant past lessons from `.agent/memory/LESSONS.md` matching those tags are automatically displayed to warn the agent before coding starts.
Agents and humans can also query context by topic anytime:
```bash
# Query lessons and ADRs for a specific topic
.agent/scripts/kit-context --topic auth
```
