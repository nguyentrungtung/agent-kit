# Clean code — manifesto for every language

The stack rules (`.agent/rules/stack/`) say HOW in each language; this file says WHAT good code is everywhere.
Machine-checked limits are enforced by the stack linters; the rest is checked in review (`kit-review` / mp-code-review).

## 1. Reuse before you write
- Before adding a function/class: `codegraph explore "<concept>"` (or grep) for existing code that does it. Extend or reuse; do not duplicate.
- Duplicated blocks above the threshold fail CI (`kit-run dup`, jscpd). Extract the shared shape, call it from both places.

## 2. Small, deep, honest units
| Limit (default) | Enforced by |
|---|---|
| Cyclomatic / cognitive complexity per function ≤ 10 / 15 | ESLint `complexity`, Ruff `C901`, gocognit, PHPStan cognitive-complexity, CA1502, clippy |
| Function ≤ ~60 lines, ≤ 4 parameters, nesting ≤ 3 | ESLint `max-lines-per-function` / `max-params` / `max-depth`, Ruff `PLR0913`, review |
| File / class with one reason to change | review (Divergent Change smell) |
- Prefer **deep modules**: a small interface hiding a lot of behaviour (mp-codebase-design). Avoid pass-through layers (Middle Man).
- Names reveal intent in the project's domain language (`docs/GLOSSARY.md`). No abbreviations nobody uses, no `data`, `manager`, `util`, `helper` dumping grounds.

## 3. Principles
- **SOLID** where it buys something: single responsibility, depend on abstractions at boundaries (ports), keep interfaces small.
- **KISS / YAGNI**: no speculative generality — no parameters, hooks or abstractions the spec does not need.
- **DRY for knowledge, not for text**: one business rule in one place; two similar lines that change for different reasons may stay separate.
- **Make illegal states unrepresentable**: value objects / enums / types instead of primitives and flags (Primitive Obsession).
- **Pure core, effects at the edges**: business logic without I/O; I/O in adapters — easy to test, easy to replace.
- **Fail fast and explicitly**: validate at boundaries, typed errors inside (see error-handling.md).

## 4. Design patterns — use when the problem is present, not to decorate
| Problem | Pattern | Not when |
|---|---|---|
| Behaviour varies by type/config (repeated switches) | Strategy / polymorphism | one switch in one place |
| Creation logic is complex or must be swappable | Factory / builder | a constructor is enough |
| Talk to an external system / framework | Adapter (port + adapter, hexagonal) | it is your own module |
| Persist aggregates, hide the ORM from the domain | Repository | simple CRUD with an active-record framework convention |
| Cross-cutting behaviour around calls (retry, cache, metrics) | Decorator / middleware | it is business logic |
| React to something that happened, decouple modules | Domain events / observer (+ outbox for reliability) | the caller needs the result now |
| Complex business rule combinations | Specification / policy object | one `if` |
| Long multi-step process with failure handling | Saga / process manager | single transaction |
Anti-patterns to reject in review: God object, anaemic domain with fat services where rules belong to entities, service locator,
singletons with mutable state, inheritance for code reuse, magic numbers/strings, boolean parameters that switch behaviour, comments explaining unclear code instead of clearer code.

## 5. Comments & docs
Code says what and how; comments say **why** (constraint, trade-off, link to ADR/issue). Public APIs have doc comments. No commented-out code, no TODO without a task id.
