# API design (HTTP/REST)

- Contract first: `docs/api/openapi.yaml` (OpenAPI 3.1) changed in the same PR as the code — playbook `kit-api` (module api).
  Lint: `kit-run api` (Spectral). Breaking changes are blocked in CI (oasdiff) unless versioned + deprecated.
- Resources are plural nouns (`/orders/{id}`), verbs via HTTP methods; JSON `camelCase` fields; ISO-8601 UTC dates.
- Status codes: 200/201(+Location)/204, 400 validation, 401 unauthenticated, 403 forbidden, 404, 409 conflict, 422 business rule, 429, 5xx.
- Errors as RFC 9457 Problem Details. Validation errors list field + message.
- Every list endpoint paginates (cursor or page/size with a max), supports stable sorting; filters are explicit query params.
- Idempotency: PUT/DELETE idempotent; POST that creates money/orders accepts an `Idempotency-Key`.
- Never expose internal ids/entities you don't intend to support; DTOs are the contract.
