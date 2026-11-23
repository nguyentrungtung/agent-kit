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

## Rules & Style Guide
Full documentation style guide: `docs/STYLEGUIDE.md`. Every agent creating or editing markdown docs MUST obey:
1. **Diataxis Framework:** Classify the doc into one quadrant (Tutorial, How-to, Reference, Explanation). Never mix disparate purposes on one page.
2. **Heading Discipline:** Exactly one `# H1` title at top. Heading hierarchy strictly sequential (`#` → `##` → `###`); never skip levels.
3. **Front Matter:** Living docs carry front matter `title, category, status, owner, updated` (`kit-new doc`). Stale living docs are bugs.
4. **Code Fences:** Always specify language tag after backticks (` ```bash `, ` ```typescript `); never leave raw backticks.
5. **Diagrams:** Mermaid/PlantUML node labels with spaces or symbols must be quoted. Validate syntax via `kit-run docs`.
6. **Callouts:** Use GitHub alerts (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`).
7. **Relative Links:** Use relative paths only (`[text](../path/file.md)`); never machine-specific absolute paths.
8. **Single Source of Truth:** Never duplicate paragraphs; link instead (task → change → spec → UC). One fact, one home.
9. **Living Docs Rule:** A PR that changes behaviour, structure, or a contract without updating the matching living doc is incomplete (Definition of Done).
10. `docs/README.md` is the map — add new top-level docs there.
