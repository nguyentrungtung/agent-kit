# Go rules (community standards)

Sources: **Effective Go**, **Go Code Review Comments**, Google Go Style Guide, standard project layout conventions (`cmd/`, `internal/`).

| Rule | Enforced by |
|---|---|
| gofmt / gofumpt / goimports formatting | `kit-run format_check`, golangci formatters |
| vet, staticcheck, errcheck, revive, gosec… | `golangci-lint run` (`kit-run lint`) |
| Data races | `go test -race` |
| Known vulnerabilities | `govulncheck` |

## Naming
- Short, lower-case package names, no `util`/`common`; no stutter (`order.Service`, not `order.OrderService`).
- `MixedCaps`; initialisms keep case (`userID`, `HTTPServer`). Receivers: 1–2 letters, consistent.
- Interfaces small, named by behaviour (`Reader`), defined **where they are used** (consumer side). Accept interfaces, return structs.

## Errors
- Return errors, don't panic (panic only for programmer bugs at init). Check every error.
- Wrap with context: `fmt.Errorf("load order %s: %w", id, err)`; inspect with `errors.Is/As`. Sentinel errors `ErrXxx`, types `XxxError`.
- Error strings lowercase, no punctuation.

## Context & concurrency
- `ctx context.Context` is the first parameter of anything doing I/O; never stored in structs.
- Every goroutine has an owner and a way to stop (ctx / `errgroup`). Close channels from the sender only.
- HTTP clients/servers always have timeouts.

## Structure
- `cmd/<app>/main.go` only wires dependencies; logic in `internal/`. No global mutable state; dependencies passed explicitly.
- Logging with `log/slog` structured fields; never log secrets.

## Tests
- Table-driven tests, `t.Run` subtests, `t.Parallel()` where safe, `testing/fstest`/httptest instead of real I/O. Testcontainers for DB integration.
