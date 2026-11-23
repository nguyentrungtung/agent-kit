# Rust rules (community standards)

Sources: **Rust API Guidelines**, rustfmt defaults, Clippy lints, the Rust Book error-handling chapter.

| Rule | Enforced by |
|---|---|
| Formatting | `cargo fmt --check` |
| Lints, zero warnings; `unwrap`/`panic`/`todo` denied | `cargo clippy -D warnings` + `[lints]` in Cargo.toml |
| No `unsafe` (unless an ADR allows a module) | `unsafe_code = "forbid"` |
| Advisories, licenses, duplicate deps | `cargo deny check` |

## Naming (RFC 430)
`snake_case` fns/vars/modules · `UpperCamelCase` types/traits/enum variants · `SCREAMING_SNAKE_CASE` consts/statics ·
conversions `as_`/`to_`/`into_`, getters without `get_`.

## Errors
- Libraries: typed errors with `thiserror`; applications: `anyhow` with `.context("…")` at boundaries.
- `?` for propagation; no `unwrap()`/`expect()` outside tests and provably-infallible cases (comment why).

## Design
- Make illegal states unrepresentable (enums, newtypes); borrow (`&str`, `&[T]`) in params, own in return.
- Implement common traits (`Debug`, `Clone`, `PartialEq`, `Default`) where sensible; `#[must_use]` on builders/results.
- Async: one runtime (tokio); no blocking calls in async fns (`spawn_blocking`). Logging/tracing via `tracing`.

## Tests
- Unit tests in `mod tests` next to code; integration tests in `tests/`; doc tests for public API examples.
