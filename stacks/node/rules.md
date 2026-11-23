# TypeScript / JavaScript rules (community standards)

Sources: TypeScript handbook (strict mode), typescript-eslint `strict-type-checked`, Prettier, Node.js best practices.

| Rule | Enforced by |
|---|---|
| Formatting | Prettier (`kit-run format_check`) |
| Lint, zero warnings | ESLint flat config (`kit-run lint`) |
| `strict` + `noUncheckedIndexedAccess` etc. | `tsc --noEmit` (`kit-run typecheck`) |
| No circular deps, no prod→devDependency imports, layer rules | dependency-cruiser (`kit-run arch`) |
| No high/critical vulnerable deps | `npm audit` (`kit-run audit`) |

## Naming
`PascalCase` types/classes/components/enums · `camelCase` variables/functions · `UPPER_SNAKE_CASE` true constants ·
files `kebab-case.ts` (React components may be `PascalCase.tsx` if the project already does) · no `I` prefix on interfaces.

## Types
- **No `any`.** Use `unknown` and narrow (type guards, zod/valibot at boundaries). No non-null `!` without a comment why it is safe.
- Validate all external input (HTTP body, env, files, queues) with a schema at the edge; derive types from the schema.
- Prefer `type` unions + exhaustive `switch` with `never` check over enums; `as const` objects for constants.
- Exported functions have explicit return types. Keep functions pure where possible.

## Async & errors
- Every promise is awaited, returned or explicitly `void`-ed. No floating promises; `Promise.all` for independent work.
- Throw `Error` subclasses with `cause`; never throw strings. Catch with `unknown` and narrow.
- No `console.log` in app code — use the project logger (pino/winston) with structured fields; never log secrets/PII.

## Modules
- ESM. Import order handled by tooling; no deep imports into another module's internals (use its `index.ts`).
- Config only from a typed, validated `config` module reading `process.env` once.

## Tests
- Vitest/Jest — follow what the project uses. Arrange/Act/Assert, no real network (msw/nock), deterministic time (fake timers).
