# PHP rules (community standards)

Sources: PSR-1 (basic coding), PSR-4 (autoloading), **PER Coding Style 2.0** (replaces PSR-12),
PSR-3 (logger), PSR-7/15/17 (HTTP), PSR-11 (container), PSR-20 (clock). Tools decide formatting — do not argue with them.

| Rule | Enforced by |
|---|---|
| Formatting = PER-CS 2.0 (4 spaces, braces, spacing, imports) | `php-cs-fixer` (`kit-run format_check`) |
| `declare(strict_types=1);` first statement of every PHP file | `php-cs-fixer` |
| Types correct at PHPStan level 8 + strict rules | `phpstan` (`kit-run typecheck`) |
| Layers: Presentation → Application → Domain ← Infrastructure | `deptrac` (`kit-run arch`) |
| `composer.json` valid, lock committed | `composer validate --strict` |
| Known-vulnerable packages blocked | `composer audit` |

## Structure & naming (PSR-1, PSR-4)
- One class/interface/trait/enum per file; file name = class name; namespace mirrors the directory under the PSR-4 root.
- `StudlyCaps` classes, `camelCase` methods and properties, `UPPER_SNAKE` class constants, `snake_case` DB columns.
- Interfaces describe a capability (`OrderRepository`, `Clock`), not `IOrderRepository`. Suffix `Interface` only if the project already does.
- Files either declare symbols or cause side effects — never both.

## Language
- Type every parameter, return and property. `mixed` only at system edges, then narrow immediately.
- Prefer `readonly` properties/classes, constructor promotion, `enum` instead of class constants for closed sets, `match` instead of `switch`.
- `final` by default for classes that are not designed for extension.
- Strict comparison (`===`); no `@` error suppression; no `extract()`, `eval()`, variable variables.
- No business logic in static helpers or global functions; inject dependencies through the constructor (PSR-11 container only at the composition root).
- Value objects for money, email, IDs — not raw strings/floats. Money is never `float`.
- Dates via `DateTimeImmutable` + an injected clock (PSR-20) so tests are deterministic.

## Errors & logging
- Throw domain-specific exceptions (`OrderNotFound extends \DomainException`); catch only where you can handle or translate.
- Never swallow exceptions; never return `false`/`null` to signal errors in new code.
- Log through PSR-3 `LoggerInterface` with context arrays (`$logger->info('order.placed', ['orderId' => $id])`), never string-concatenated secrets/PII.

## Security
- SQL only through parameter binding / query builder / ORM. No string-built SQL.
- Escape output by context (HTML, attribute, JS, URL). Validate all input at the boundary (request DTO / form request).
- Passwords: `password_hash()` / `password_verify()` (or framework hasher). Randomness: `random_bytes()` / `random_int()`.
- No `unserialize()` on untrusted data; prefer JSON.

## Tests
- PHPUnit (or Pest if already used). Test class mirrors the class under test: `tests/Unit/Domain/OrderTest.php`.
- Unit tests have no DB/network; integration tests are separate suites. Every bug fix gets a regression test.
