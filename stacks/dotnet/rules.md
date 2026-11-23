# C# / .NET rules (community standards)

Sources: **Microsoft .NET coding conventions** + Framework Design Guidelines, Roslyn analyzers (CAxxxx/IDExxxx).

| Rule | Enforced by |
|---|---|
| Style & naming from `.editorconfig` | `dotnet format --verify-no-changes`, build (`EnforceCodeStyleInBuild`) |
| Nullable reference types, analyzers, zero warnings | `Directory.Build.props` (`TreatWarningsAsErrors`) |
| Layer dependencies | NetArchTest `ArchitectureTests` (`kit-run arch`) |
| Vulnerable packages | `dotnet list package --vulnerable` |

## Naming
`PascalCase` types/methods/properties/constants · `IPascalCase` interfaces · `_camelCase` private fields · `camelCase` locals/params ·
`Async` suffix on async methods · file-scoped namespaces matching folders.

## Language
- Nullable enabled: no `!` suppression without a comment; validate inputs with `ArgumentNullException.ThrowIfNull`.
- `record` for DTOs/value objects; `readonly`/`init` where possible; `sealed` classes by default.
- Async all the way: no `.Result`/`.Wait()`; pass `CancellationToken` through every async I/O call.
- DI via constructor (primary constructors OK); options pattern (`IOptions<T>` + validation) for config.
- `decimal` for money; `DateTimeOffset`/`TimeProvider` for time.

## Errors & logging
- Specific exceptions; no catch-all without rethrow; ProblemDetails for HTTP errors.
- `ILogger<T>` with message templates (`"Order {OrderId} placed"`), never string interpolation; no secrets/PII.

## Tests
- xUnit + FluentAssertions/Shouldly, `WebApplicationFactory` for API tests, Testcontainers for DB.
