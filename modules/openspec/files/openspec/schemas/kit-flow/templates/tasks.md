# Tasks

<!-- One `## N.` group = one kit task = one agent session. Put the TASK id in the heading.
     Order inside each group: tests first (red) → implement → kit-run check → docs → checkpoint. -->

## 1. <!-- Group title --> (TASK-NNN)

- [ ] 1.1 Write failing tests for <!-- scenario names --> and verify they fail for the right reason
- [ ] 1.2 Implement <!-- what --> and verify the tests from 1.1 pass
- [ ] 1.3 Run `.agent/scripts/kit-run check` and verify it is green
- [ ] 1.4 Update living docs (<!-- docs/api, README, docs/architecture … -->) and verify they match the behaviour

## 2. <!-- Group title --> (TASK-NNN)

- [ ] 2.1 Write failing tests for <!-- scenarios --> and verify they fail
- [ ] 2.2 Implement <!-- what --> and verify the tests pass
- [ ] 2.3 Run `.agent/scripts/kit-run check` and verify it is green

## Workflow follow-up

- `.agent/scripts/kit-task finish` for each task (the last one validates and archives this change into openspec/specs).
- Human reviews and merges each PR.
