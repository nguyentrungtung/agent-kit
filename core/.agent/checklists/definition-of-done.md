# Definition of Done — all must be true before `kit-task finish` (machine part: `kit-task verify`)

## Workflow (task file)
- [ ] §1 Understand, §2 Clarifications, §3 Solution, §4 Test plan, §7 Result are filled
- [ ] Tests were written first and seen failing; `docs/qa/TASK-NNN.md` covers every AC
- [ ] Active plugin spec / change gates pass (when enabled)

## Scope
- [ ] Every acceptance criterion in the task file is met and ticked
- [ ] Nothing outside the task scope was changed (no drive-by refactors; note them as new tasks)

## Quality
- [ ] `.agent/scripts/kit-run check` is green (format, lint, types, tests, secrets)
- [ ] New/changed logic has tests: happy path, edge cases, error paths (see `docs/qa/TASK-NNN.md`)
- [ ] Bug fix includes a regression test that failed before the fix
- [ ] No TODO/FIXME without a linked task; no debug prints; no commented-out code
- [ ] Public functions/APIs documented; names follow CONVENTIONS.md

## Safety
- [ ] `security.md` checklist reviewed for the changed area
- [ ] No secrets / `.env` / keys in diff; new config names added to `.env.example`
- [ ] DB migration is reversible (or a rollback note exists in the task file)
- [ ] Backward compatibility considered (API contracts, data, feature flags)

## Docs & memory
- [ ] Task file: progress log + handoff notes updated
- [ ] ADR written if a decision was made (`kit-adr`)
- [ ] Living docs updated in this PR: docs/architecture, README, and active plugin docs (when enabled: e.g. OpenSpec specs, docs/api)
- [ ] Lesson added to LESSONS.md if something went wrong on the way
