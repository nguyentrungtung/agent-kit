# Supply chain & secrets

| Rule | Enforced by |
|---|---|
| Dependencies from official registries, lockfiles committed, versions pinned; new dependency needs a reason (task file) | review, audit |
| No HIGH/CRITICAL known vulnerabilities unfixed without an accepted-risk entry | dependency audit, trivy (CI) |
| SBOM generated for every release (CycloneDX) | `kit-run sbom`, CI artefact |
| Licences: permissive (MIT/Apache/BSD/ISC) by default; copyleft (GPL/AGPL/LGPL) needs approval | SBOM review |
| CI actions pinned; workflow `permissions:` least privilege; OIDC instead of long-lived cloud keys | actionlint, review |
| Secrets live in a secret manager / CI secrets; rotated; never in repo, images, logs or tickets | gitleaks, guard hooks |
