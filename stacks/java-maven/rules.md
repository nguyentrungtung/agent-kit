# Java rules (community standards)

Sources: **Google Java Style Guide**, Effective Java (3rd ed.), Oracle secure coding guidelines.
Formatting is done by google-java-format (Spotless) — never hand-format, never disable it per file.

| Rule | Enforced by |
|---|---|
| Google Java Style formatting, import order, unused imports | Spotless (`kit-run format_check`) |
| Naming, Javadoc on public API, no star imports, line length 100 | Checkstyle `google_checks.xml` (`kit-run lint`) |
| Layering, no cycles, no field injection, framework-free domain | ArchUnit `ArchitectureTest` (`kit-run arch`) |
| Coverage ≥ `coverage_min` | JaCoCo report in CI |
| No known-vulnerable deps (CVSS ≥ 7) | OWASP dependency-check (`kit-run audit`) |

## Naming
`UpperCamelCase` types · `lowerCamelCase` methods/fields/params · `UPPER_SNAKE_CASE` constants (static final immutable) ·
packages all lowercase, no underscores · test class `<Class>Test`, integration `<Class>IT`.

## Language (Effective Java)
- Prefer immutability: `record` for DTOs/value objects, `final` fields, `List.copyOf` for defensive copies.
- Never return `null` collections; return empty. `Optional` only as a **return type**, never fields/params.
- Use `var` only when the type is obvious from the right-hand side.
- Override `equals`/`hashCode` together; entities compare by id.
- No raw types, no unchecked casts without a justification comment.
- Static utilities: `final` class + private constructor. Prefer composition over inheritance.
- `BigDecimal` for money (with explicit `RoundingMode`), `java.time` for dates (`Instant` in UTC for storage), injected `Clock` in services.

## Errors & logging
- Unchecked domain exceptions with meaningful names; never `catch (Exception e)` without rethrow/translation; never empty catch.
- Don't use exceptions for control flow. Preserve the cause when wrapping.
- SLF4J with parameters: `log.info("order placed orderId={}", id)` — no string concat, no `System.out`, never log secrets/PII.

## Concurrency
- Prefer `java.util.concurrent` / virtual threads (Java 21) over manual `Thread`. Shared mutable state needs a documented strategy.

## Tests
- JUnit 5 + AssertJ + Mockito. Given/When/Then structure, one behaviour per test, descriptive `@DisplayName` or method names.
- Integration tests with Testcontainers (real DB), not H2 in "compatibility" mode.
