# Containers

| Rule | Enforced by |
|---|---|
| Multi-stage builds; runtime stage has only what runs the app | hadolint, review |
| Pinned base image tags (major.minor at least; digest for prod), no `latest` | hadolint DL3007 |
| Runs as non-root (`USER`), read-only root filesystem where possible, no `--privileged` | hadolint DL3002, kubeconform/checkov |
| No secrets in `ARG`/`ENV`/layers; secrets mounted at runtime | secrets scan, trivy |
| One process per container, logs to stdout/stderr, handles SIGTERM gracefully | review |
| Healthcheck / liveness + readiness probes defined | compose `healthcheck`, K8s probes review |
| Resource requests/limits set in K8s; `restart` policy in compose | kubeconform, review |
| Images scanned (HIGH/CRITICAL block) and, for prod, signed | trivy in CI |
| `.dockerignore` excludes `.git`, secrets, build output | review |
