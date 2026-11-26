---
name: kit-docker
description: Build and maintain the local runtime — multi-stage, non-root Dockerfiles per component and a compose.yaml assembled from the service catalog (.agent/docker/catalog — postgres, mysql, redis, rabbitmq, kafka, minio, mailpit, keycloak, observability), wired with healthchecks and env vars documented in .env.example. Use when the project needs docker compose, a dev environment, a new backing service, or after kit-sa decides the containers.
---
# kit-docker — local runtime with Docker Compose

Scope: **local development and CI test environments only.** Production deployment is designed in kit-sa and run by humans.

## Steps
1. Read `docs/architecture/SOLUTION.md` (containers) and `.agent/project.yaml` (`components`). The existing `compose.yaml` and `Dockerfile`s are the base — extend them, don't rewrite.
2. **Dockerfile per component** (start from the generated one): multi-stage, pinned base image tags, dependency layer before the source copy,
   cache mounts, prod deps only in the runtime stage, **non-root user**, `EXPOSE` the app port, no secrets in `ARG`/`ENV`/layers. Keep `.dockerignore` tight.
3. **Backing services**: copy the fragment from `.agent/docker/catalog/<service>.yml` into `services:` and its volume (header `# volumes:`) into `volumes:`.
   Every service has a `healthcheck`; apps use `depends_on` with `condition: service_healthy`. Optional tooling goes behind `profiles:`.
4. **Configuration**: every variable used by compose or the app is listed (name + harmless placeholder) in `.env.example`
   (header `# env:` of each catalog file). Compose uses `${VAR:-local-default}` only for non-sensitive local defaults. Never write a real `.env`.
5. **Validate**: `docker compose config -q` (syntax), then `.agent/scripts/kit-run up` → services healthy → smoke request → `.agent/scripts/kit-run down`.
   If a service fails, read `.agent/scripts/kit-run logs`; never loosen a healthcheck just to make it pass.
6. **Document** in `README.md`: how to start (`kit-run up`), a URL/port table, and how to reset local data (a human runs the volume reset).

## Rules
- Pin versions (`postgres:16-alpine`); never `latest` for stateful services. Expose only ports a developer needs.
- One process per container; logs to stdout/stderr; graceful shutdown on SIGTERM.
- Destroying volumes, pruning Docker or pushing images needs human approval (the guard hook asks).
