# Error handling

- Fail fast at boundaries (invalid input → 4xx with a clear message), fail loud inside (unexpected → exception, logged once).
- Never swallow errors. A catch block must handle, translate (keeping the cause) or rethrow.
- Domain errors are named types (`InsufficientStock`), not generic exceptions or magic return values.
- Log an error once, at the boundary that handles it — not at every layer.
- Retries only for transient, idempotent operations, with backoff + jitter + a limit. External calls always have timeouts.
- HTTP APIs return RFC 9457 Problem Details (`type`, `title`, `status`, `detail`, `instance`) + a correlation id.
