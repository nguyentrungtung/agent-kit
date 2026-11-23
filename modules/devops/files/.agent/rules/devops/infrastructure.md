# Infrastructure & environments

| Rule | Enforced by |
|---|---|
| All infrastructure is code (Terraform / compose / manifests) in the repo; no manual console changes ("ClickOps"). Drift is a bug | review, `terraform plan` in CI |
| Agents prepare changes; a human runs `apply` / deploy | Claude guard hook (asks/blocks), branch protection |
| Environments are identical in shape (same images, same IaC modules), different only in size and config | review |
| Remote state with locking and encryption; state never committed | `.gitignore`, secrets scan |
| Pin versions: providers, modules, base images, actions, Helm charts | tflint, hadolint (DL3007), actionlint |
| Tag every cloud resource: `project`, `env`, `owner`, `cost-center` | tflint / checkov rules |
| Least privilege everywhere: IAM per service, no wildcard `*` actions, short-lived CI credentials (OIDC), no long-lived keys | checkov / trivy config, review |
| Production data never copied to lower environments un-anonymised | review, data-protection rule |
| `terraform fmt` / `validate` / tflint clean | `kit-run ops` |
