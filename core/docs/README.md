# Documentation map
Rule: read **living** docs to understand the system; change records only for the task you are on. Details: `.agent/rules/core/documentation.md`.

| Where | What | Kind | Created / updated by |
|---|---|---|---|
| `../openspec/specs/` | Current behaviour per capability (requirements + scenarios) | living | archiving an OpenSpec change (`kit-task finish`) |
| `architecture/` | Solution architecture, C4, data model, sizing & cost (module `sa`) | living | `kit-sa` |
| `api/` | OpenAPI contracts | living | same PR as the API change |
| `ba/` | Brief, stakeholders, processes, use cases, stories, rules, RTM (module `ba`) | living (business) | `kit-ba`, `kit-new usecase/story` |
| `../openspec/changes/` | Changes in progress: proposal, spec deltas, design, tasks | change | `kit-new change`, `/openspec-propose` |
| `../.agent/tasks/` | One execution record per task (archive/ when done) | change | `kit-task` |
| `qa/` | Test cases per task (`TASK-NNN.md`) + project test plan | change | `kit-new testplan`, `kit-testcases` |
| `adr/` | Architecture decision records | decision | `kit-new adr`, `kit-adr` |
| `plan/` | Roadmap and milestones | living (plan) | `kit-plan` |
| `security/` | Threat model, review results | living | `kit-security` |
| `daily/` | Daily / weekly reports | report | `kit-daily` |
