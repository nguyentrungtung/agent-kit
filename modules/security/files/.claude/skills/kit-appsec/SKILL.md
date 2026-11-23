---
name: kit-appsec
description: Application security by design — threat model (data-flow diagram with trust boundaries + STRIDE), pick the OWASP ASVS level, turn controls into testable security requirements (OpenSpec scenarios), design authentication/authorization and secrets, register personal data and legal basis (Vietnam Law 91/2025/QH15, Decree 356/2025/ND-CP; GDPR if EU users), and review supply chain (SBOM, licences). Use when starting a project, before an epic that touches auth/data/integrations, or when asked for a security design. Per-diff reviews use kit-security.
---
# kit-appsec — security architecture (design time)

Rules: `.agent/rules/security/` + `.agent/rules/core/security.md`. Output: `docs/security/` (living) + scenarios in OpenSpec changes.
Per-change code review stays with **kit-security** / `security-reviewer`.

## 1. Inputs
`docs/architecture/SOLUTION.md` (containers, integrations), `docs/platform/PLATFORM.md` (zones, secrets), `docs/ba/` (actors, data),
`openspec/specs/` (current behaviour). Ask ONE batch about: data sensitivity, users/regions (VN / EU), compliance, threat actors, budget.

## 2. Threat model → `docs/security/THREAT-MODEL.md`
1. **Data-flow diagram** with trust boundaries (internet ↔ edge ↔ app ↔ data ↔ third parties), assets and entry points.
2. **STRIDE** per element/flow: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege.
3. Rate each threat likelihood × impact → risk; pick a control (mitigate / transfer / accept with a named human owner).
4. Abuse cases for the riskiest features (e.g. "attacker enumerates order ids").

## 3. Security requirements
- Choose the **ASVS level** (ADR): L1 basic, **L2 default for business apps with personal data**, L3 high-value (finance/health/critical).
- Map the relevant ASVS chapters (auth, session, access control, validation, crypto, errors/logging, data protection, API, config)
  to concrete controls; each control becomes a **requirement + scenario** in the OpenSpec change it belongs to
  (e.g. `#### Scenario: SEC — locked after 5 failed logins`), so it is implemented and tested like any feature.

## 4. Design topics (ADR each)
- **AuthN**: OIDC/OAuth 2.1 provider vs built-in; MFA; password policy (NIST 800-63B); session vs token; refresh/rotation.
- **AuthZ**: model (RBAC / ABAC / ReBAC), where enforced (server, every request, object-level), permission naming.
- **Secrets & keys**: manager per environment, rotation, KMS/envelope encryption, no secrets in code/images/CI logs.
- **Crypto**: TLS 1.2+ everywhere, at-rest encryption, approved algorithms only, no home-made crypto.

## 5. Personal data → `docs/security/PII-REGISTER.md`
Inventory: data item, category (basic / sensitive per Law 91/2025), purpose, legal basis/consent, where stored, retention, who accesses,
cross-border transfer, deletion path. Flag impact-assessment duties (Decree 356/2025) and data-subject rights (access, correction, deletion).
Not legal advice — mark items for the project's legal/DPO review.

## 6. Supply chain
SBOM (`.agent/scripts/kit-sec-scan sbom`), licence policy (no copyleft in proprietary apps without approval), dependency update policy,
pinned CI actions, signed images for prod.

## 7. Verify & hand-off
DAST baseline on a running local/staging app: `.agent/scripts/kit-sec-scan dast <url>` (OWASP ZAP baseline).
Update `docs/security/` + ADRs, summarise top risks and the controls added to changes. Accepted risks need a human name and date.
