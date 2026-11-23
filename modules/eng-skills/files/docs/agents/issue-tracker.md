# Where work items, specs and decisions live (read by the mp-* skills)

| What | Where |
|---|---|
| Work item (ticket) | `.agent/tasks/TASK-NNN-*.md` — one file per task; the current task = the `TASK-NNN` in the branch name. Archived ones: `.agent/tasks/archive/` (history only) |
| Spec of the work item | the task's **Acceptance criteria** + its OpenSpec change `openspec/changes/<change>/` (`change:` in the task front matter): `proposal.md`, `specs/**/spec.md`, `design.md`, `tasks.md` |
| Current behaviour (source of truth) | `openspec/specs/` |
| Business source | `docs/ba/` (use cases `UC-NN`, stories `US-NN`, rules `BR-NN`) |
| Decisions | `docs/adr/` (create with `.agent/scripts/kit-new adr "<title>"`) |
| Coding standards | `.agent/rules/` (project > stack > core), summary in `.agent/context/CONVENTIONS.md` |
| Domain language | `GLOSSARY.md` (repo root) |
| GitHub issues (optional) | linked via `.agent/tasks/.issues` (`TASK-NNN=<issue>`); create/update with `.agent/scripts/kit-task sync-gh` (asks first) |

Create new work items with `.agent/scripts/kit-task new "<title>" [--change <change>]` — never by hand, never directly on the tracker.
Scratch notes go in the task file's Progress log, not in a `.scratch/` folder.
