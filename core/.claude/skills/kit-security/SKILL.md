---
name: kit-security
description: Security review — secrets scan, SAST-style review of the diff against the OWASP-based checklist, dependency audit, threat-model update. Use for changes touching input, auth, data, files, network, config or dependencies, and before every release.
---
# kit-security

1. Automated: `.agent/scripts/kit-secrets-scan --all` and `.agent/scripts/kit-run audit`. If `semgrep` is installed:
   `semgrep scan --config p/default --severity ERROR --metrics=off <changed paths>`.
2. Manual review of the diff (or `security-reviewer` sub-agent) with `.agent/checklists/security.md`:
   input validation, injection, authz on every entry point (incl. object-level), secrets/PII in logs, error leakage,
   crypto/password storage, SSRF/path traversal, unsafe deserialization, new dependencies.
3. Findings: `[CRITICAL|HIGH|MEDIUM|LOW] file:line — issue — fix`. CRITICAL/HIGH block the PR → fix now.
   Accepted MEDIUM/LOW → `docs/security/THREAT-MODEL.md` "accepted risks" (module security) or the task's Risks section — needs a human name.
4. If the change adds a trust boundary/asset/integration or personal data: run the **kit-appsec** playbook (module security) to update the threat model / PII register.
5. Summary line in the task *Progress log*. Never paste secret values into any file or message.
