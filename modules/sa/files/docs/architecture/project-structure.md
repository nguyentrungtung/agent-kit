---
title: Project structure — backend + frontend + contracts
category: reference
status: draft
owner:
updated:
---
# Project structure — backend + frontend + contracts
<!-- Owned by kit-sa (§5). The Full-stack Developer places every file by THIS document; a new top-level folder needs an update here.
     Fill it from the architecture style ADR and the stack skeletons (.agent/stack/<stack>/skeletons/[<framework>/]<style>.txt);
     `kit-new module <name> --component <path>` creates a module's folders from the same skeleton. -->

## 1. Repository layout
<!-- Pick one and delete the other. -->
**Monorepo (separate backend + frontend apps)**
```
/
├── backend/                  # API — <stack/framework>, style: <modular monolith | layered>
├── frontend/                 # Web UI — <React/Vite | Next.js | …>
├── docs/
│   ├── api/openapi.yaml      # THE contract between backend and frontend (contract-first, kit-api)
│   ├── architecture/         # SOLUTION.md, this file, ui-design-system.md, data-model.md
│   └── ba/                   # requirements
├── openspec/                 # living specs + changes
├── deploy/ · infra/          # owned by DevOps
└── .agent/                   # kit: rules, tasks, scripts
```
**Single app (server-rendered UI: Laravel Blade / Next.js full-stack / Django templates)** — UI lives inside each module.

## 2. Backend module layout
<!-- Paste the skeleton of the chosen style: .agent/stack/<stack>/skeletons/<framework>/<style>.txt for a framework component
     (e.g. .agent/stack/php/skeletons/laravel/modular.txt), .agent/stack/<stack>/skeletons/<style>.txt for a plain stack. -->
```
backend/src/modules/<module>/
  api/              # controllers / routes + request/response DTOs (generated from or checked against openapi.yaml)
  application/      # use cases, ports
  domain/           # entities, value objects, rules — no framework imports
  infrastructure/   # repositories, external clients
  <module tests>
```

## 3. Frontend feature layout (1 feature ↔ 1 backend module)
```
frontend/src/
  app/                       # bootstrap, router, providers, layout
  features/<module>/         # index.ts = public API of the feature
    api/                     # hooks calling the backend through the GENERATED client (shared/api) — no hand-written types
    components/              # every data view implements empty / loading / error / success (BA wireframes)
    pages/                   # route-level screens
    __tests__/
  shared/
    api/                     # generated from docs/api/openapi.yaml by `kit-run apigen` — never edited by hand
    ui/                      # design-system components (tokens from ui-design-system.md)
    lib/                     # framework-free helpers
```

## 4. Module ↔ feature map
| Backend module | Frontend feature | Main screens (US) | API tag in openapi.yaml |
|---|---|---|---|

## 5. Rules
- Dependency direction: `features/*` → `shared/*`; never `shared` → `features`; features talk only via `index.ts`.
- One vertical slice (task) touches: migration → domain/application → api → `docs/api/openapi.yaml` → `kit-run apigen` →
  feature `api/` hook → component/page → tests at each level.
- Enforced by: <arch test config files — deptrac.yaml / .dependency-cruiser.cjs / …>.
