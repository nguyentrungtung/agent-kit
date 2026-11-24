# Testing

- Every acceptance criterion has at least one automated test. Every bug fix starts with a failing regression test.
- Pyramid: many fast unit tests (no I/O) → fewer integration tests (real DB via containers) → few end-to-end tests.
- Tests are deterministic: no sleeps, real clocks, random seeds or network; inject clock/ids/randomness.
- Name tests by behaviour (`rejects_order_when_stock_is_insufficient`); Arrange/Act/Assert (Given/When/Then).
- Test public behaviour, not private methods or framework internals. Mock only what you own at process boundaries.
- Never delete, skip or weaken a failing test to get green — fix the code or raise it with the human.
- Coverage target `coverage_min` (project.yaml) is a floor, not a goal; critical domain logic aims higher.
- Test cases are designed first in `docs/qa/TASK-NNN.md` (`kit-testcases`) covering the **Core 6 Test Matrix**: Happy path, Boundary values, Negative/Errors, Security/AuthZ, State transitions, and Resilience/Concurrency.
- For UI components: verify responsive viewports (mobile/desktop), the 4 UI states (empty, loading, error, success), and Accessibility (a11y: WCAG AA, keyboard navigation, aria attributes).
