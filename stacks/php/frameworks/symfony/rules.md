# Symfony rules

Formatting: php-cs-fixer `@Symfony` (Symfony Coding Standards). Types: PHPStan + phpstan-symfony.

- Services are autowired via constructor injection; no `$container->get()` in application code. Mark services `final` + `readonly` where possible.
- Controllers are thin: map request (`#[MapRequestPayload]` DTO + Validator constraints) → handler/service → response. No Doctrine queries in controllers.
- Doctrine: queries in Repository classes only; entities keep invariants (no public setters for everything); migrations via `doctrine:migrations:diff`, reviewed before commit, never edited after running on shared envs.
- Use Messenger for async work; handlers idempotent.
- Configuration: env vars resolved in `config/` (`%env(...)%`); secrets via Symfony Secrets/vault, never in `.env` committed files.
- Security: voters for authorization, `#[IsGranted]` on controllers; CSRF on forms.
- Tests: `KernelTestCase` for services, `WebTestCase` for HTTP; Foundry/fixtures for data.
