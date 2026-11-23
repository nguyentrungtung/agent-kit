---
name: kit-devops
description: Platform / DevOps design and delivery — environments, infrastructure as code (Terraform or Compose on VPS or Kubernetes), container images, CI/CD pipelines, deployment strategy (rolling, blue-green, canary), secrets, observability (logs, metrics, traces, SLOs, alerts), backup and disaster recovery, sizing & cost, runbooks — documented in docs/platform/. Use after kit-sa has fixed the containers, or when asked about hosting, deployment, pipelines, monitoring or operations.
---
# kit-devops — platform & operations (you prepare, humans apply)

Rules: `.agent/rules/devops/` + `.agent/rules/core/security.md`. Output: `docs/platform/` (living) + config files.
Decisions that constrain the whole system (hosting model, orchestrator, cloud) are ADRs (`kit-new adr`).

## 1. Inputs
`docs/architecture/SOLUTION.md` (containers, NFR scenarios: availability, RTO/RPO, latency, load), `docs/security/` (zones, secrets),
`.agent/project.yaml` (components), existing Dockerfiles/compose/infra. Missing numbers → ask ONE batch (≤ 7), else `ASSUMPTION:`.

## 2. Platform design → `docs/platform/PLATFORM.md`
1. **Environments**: local (compose) · dev/staging · prod — purpose, data (synthetic/anonymised/real), access, promotion path.
2. **Hosting model** (ADR): VPS + Docker Compose · managed containers/PaaS · Kubernetes. Choose the simplest that meets the scenarios;
   K8s only when scale, team and ops maturity justify it. Cloud/vendor choice with cost and lock-in.
3. **Topology**: network zones, ingress/TLS, egress, DNS, managed DB/cache/queue vs self-hosted — C4 deployment diagram.
4. **Build & release**: image strategy (multi-stage, non-root, pinned, scanned, signed), versioning (semver from tags), artefact registry.
5. **CI/CD**: pipeline stages (guard → quality → security → build image → deploy staging → smoke → manual approval → prod),
   required checks, environment protection, who approves.
6. **Deployment strategy**: rolling / blue-green / canary, DB migration order (expand → migrate → contract), feature flags, rollback.
7. **Secrets & config**: secret manager per environment, rotation, no secrets in images/repos/CI logs, `.env.example` names only.
8. **Observability**: structured logs, metrics (RED/USE), traces (OpenTelemetry), dashboards, **SLOs + error budget + alerts** (each alert → runbook).
9. **Backup & DR**: what, frequency, retention, encryption, **restore test** schedule, RTO/RPO met how.
10. **Sizing & cost** → `docs/platform/sizing.md` (show the arithmetic).

## 3. Implement (config only, via kit-task)
- Local: Dockerfiles + compose with the **kit-docker** playbook.
- IaC in `infra/` (Terraform modules per environment, remote state with locking, no secrets in state outputs) — plan only.
- K8s manifests/Helm in `deploy/` (resources, probes, PDB, security context non-root/read-only FS, NetworkPolicy).
- CI/CD in `.github/workflows/` (pinned action versions, least-privilege `permissions:`, no untrusted input in `run:` — use env vars).
- Runbooks: `.agent/scripts/kit-new runbook "<alert or operation>"`.
- Validate: `.agent/scripts/kit-ops-lint` (hadolint, actionlint, shellcheck, terraform fmt/validate/tflint, kubeconform, compose config).

## 4. Hand-off
Summarise to the human: what must be applied by a person (terraform apply, secrets to create, DNS, approvals), cost, risks, open questions.
Update `docs/architecture/SOLUTION.md` § Platform with a 3-line summary + link. Never run apply / deploy / push.
