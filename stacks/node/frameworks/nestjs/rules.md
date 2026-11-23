# NestJS rules

- One feature = one module (`orders/orders.module.ts`) exposing only what other modules need (`exports`).
- Controllers: routing + DTO validation (`class-validator` + global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`) → call a service. No DB access in controllers.
- Services hold use cases; repositories/adapters behind injected interfaces (custom providers with tokens) so they can be mocked.
- Errors: throw domain errors, map them in an exception filter to HTTP problems; never leak stack traces.
- Config via `@nestjs/config` with schema validation; no `process.env` outside the config module.
- Auth via Guards; authorization decorators (`@Roles`) checked in guards, not in handlers.
- Tests: unit tests with `Test.createTestingModule` + mocks; e2e with supertest against an in-memory or containerised DB.
