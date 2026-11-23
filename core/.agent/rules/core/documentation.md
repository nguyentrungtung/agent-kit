# Documentation — what goes where, and when

Separate by **lifetime**. Agents read living docs to understand the system; change records only for the task at hand.

| Kind | Question it answers | Location | Updated | Read |
|---|---|---|---|---|
| **Living — behaviour** | What does the system do now? | `openspec/specs/<capability>/spec.md` | By archiving the change, in the PR that changes the code | Always first |
| **Living — structure** | How is it built? | `docs/architecture/` (SOLUTION, data model, sizing), `.agent/context/ARCHITECTURE.md` (summary) | When structure/data/infrastructure changes | Before design |
| **Living — contracts** | How do others call it? | `docs/api/` (OpenAPI) | Same PR as the API change | When touching APIs |
| **Business** | What do users need? | `docs/ba/` (brief, use cases, stories, rules, RTM) | When requirements change | When planning |
| **Change in progress** | What are we changing and why? | `openspec/changes/<change>/` (proposal, spec deltas, design, tasks) | During the change; archived when done | During that change |
| **Execution record** | What did this task do, ask, decide, verify? | `.agent/tasks/TASK-NNN-*.md` + `docs/qa/TASK-NNN.md` | Live during the task (timestamped log) | Only the active task |
| **Decisions** | Why A and not B? | `docs/adr/NNNN-*.md` (immutable; superseded, never edited) | When deciding | When questioning a choice |
| **Reports** | What happened today/this week? | `docs/daily/` | End of session | Rarely |
| **History** | — | `.agent/tasks/archive/YYYY-MM/`, `openspec/changes/archive/` | Never edited | Archaeology only |

## Rules
- Living docs carry front matter `title, status, owner, updated` (`kit-new doc`). Stale living docs are bugs.
- A PR that changes behaviour, structure or a contract without updating the matching living doc is incomplete (DoD).
- Task files record the journey (Q&A, decisions, results, timestamps) — they are not the spec. Once done they move to the archive.
- Never duplicate: link instead (task → change → spec → UC). One fact, one home.
- Create documents with `kit-new` from `.agent/templates/`; do not invent structure.
- `docs/README.md` is the map — add new top-level docs there.
