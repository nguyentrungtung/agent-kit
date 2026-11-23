---
name: kit-api
description: Design and change HTTP APIs contract-first — edit docs/api/openapi.yaml (OpenAPI 3.1) before code, follow the API rules (resources, status codes, RFC 9457 errors, pagination, idempotency, versioning), lint with Spectral, keep the framework's generated docs (springdoc, Scribe/L5-Swagger, NelmioApiDoc, @nestjs/swagger, FastAPI, Swashbuckle, swag) in sync, and avoid breaking changes (oasdiff gate in CI). Use whenever an endpoint, request/response schema or error format is added or changed.
---
# kit-api — contract-first APIs

Rules: `.agent/rules/core/api-design.md`. Contract: `docs/api/openapi.yaml` (living). Lint: `.agent/scripts/kit-run api`.

## 1. Contract first
1. From the story/spec scenarios, write or change the operation in `docs/api/openapi.yaml`: path (plural kebab-case nouns), method,
   `operationId` (camelCase), tags, request schema, every response (2xx + 400/401/403/404/409/422 as `application/problem+json`), examples.
2. Lists: cursor or page/size (max 100) + stable sort; filters as explicit query params. Creates that move money/orders accept `Idempotency-Key`.
3. Breaking change (remove/rename field, tighten validation, change type or status code)? → new version (`/v2/...` or new media type) and
   a deprecation window for the old one (`deprecated: true` + sunset date). The CI oasdiff gate fails on unannounced breaking changes.
4. `.agent/scripts/kit-run api` (Spectral) green → the contract goes into the OpenSpec change design (API contract section).

## 2. Tests from the contract
Integration tests per operation and status code (checklist `.agent/checklists/testing.md`); validate responses against the schema
(e.g. openapi-response-validator / schemathesis / RestAssured with JSON schema) so code cannot drift from the contract.

## 3. Implementation & generated docs
| Framework | Library | Rule |
|---|---|---|
| Spring Boot | springdoc-openapi | annotate DTOs; export `/v3/api-docs` and diff it against docs/api in a test |
| Laravel | Scribe or L5-Swagger | generate from FormRequests/Resources; keep docs/api as the reviewed contract |
| Symfony | NelmioApiDocBundle | same |
| NestJS | @nestjs/swagger | decorators on DTOs; `SwaggerModule` serves UI in dev |
| FastAPI | built-in | `app.openapi()`; export and diff in CI |
| ASP.NET Core | Swashbuckle / Microsoft.AspNetCore.OpenApi | same |
| Go | swaggo/swag or oapi-codegen (contract → code) | prefer generating server stubs from the contract |
Swagger UI locally: compose service `swagger-ui` (devops catalog) → http://localhost:8081.

## 4. Done
Contract updated in the same PR as the code, Spectral clean, oasdiff shows no unannounced breaking change, consumers informed of deprecations.
