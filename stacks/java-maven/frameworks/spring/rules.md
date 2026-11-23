# Spring Boot rules

- **Constructor injection only** (single constructor, no `@Autowired` on fields) — enforced by ArchUnit.
- Layers: `api` (controllers, request/response DTOs) → `application` (use cases, `@Transactional`) → `domain` (entities, rules, ports) ← `infrastructure` (JPA, clients, messaging).
  With Spring Modulith: one top-level package per module, cross-module calls only via the module's public API or events; `ApplicationModules.of(App.class).verify()` in a test.
- Controllers: no business logic, no repositories. Validate with `@Valid` + Bean Validation on request records. Never expose JPA entities — map to DTOs.
- Errors: `@RestControllerAdvice` returning RFC 9457 `ProblemDetail`; no stack traces to clients.
- `@Transactional` on application-service methods (public), `readOnly = true` for queries. Never on controllers or private methods.
- JPA: `FetchType.LAZY` by default, solve N+1 with fetch joins/entity graphs; `open-in-view: false`.
  Repositories return domain types or projections; pagination with `Pageable` for every list endpoint.
- Schema only via **Flyway** migrations (`V<yyyyMMddHHmm>__<verb>_<detail>.sql`); never edit an applied migration; `ddl-auto: validate`.
- Configuration via `@ConfigurationProperties` records (validated), not scattered `@Value`. Secrets from env/vault, never in `application*.yml`.
- Security: Spring Security with explicit `SecurityFilterChain`; deny by default; method security (`@PreAuthorize`) for business permissions.
- Observability: Actuator health/readiness, Micrometer metrics, structured logs with correlation id (MDC / tracing).
- Tests: `@WebMvcTest` for controllers, `@DataJpaTest` + Testcontainers for repositories, `@SpringBootTest` only for a few end-to-end flows.
