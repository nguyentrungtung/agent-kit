---
id: US-{{NUM}}
title: {{TITLE}}
status: draft               # draft | ready | in-progress | done
epic:
use_case: {{UC}}
priority: Must              # MoSCoW
estimate:
rules: []
updated: {{DATE}}
---
# US-{{NUM}} {{TITLE}}

**As a** … **I want** … **so that** …

## Acceptance criteria
<!-- Given/When/Then, including at least one negative path. Each becomes an OpenSpec scenario and a test. -->
- AC1 — Given … When … Then …
- AC2 — Given … When … Then … (negative)

## Business rules
<!-- BR ids only; rule text lives in REQUIREMENTS.md -->

## UI & Screen Specification
<!-- For UI features: wireframe layout, user flow, and key states so Full-stack Dev can implement FE cleanly without guessing -->
### Wireframe / Layout
<!-- Low-fi layout: ASCII box, Markdown table, or Mermaid diagram -->
```
+-------------------------------------------------------------+
| [Header / Screen Title]                                     |
| [Input Fields / Controls]                                   |
| [Button: Primary Action]    [Button: Cancel/Secondary]      |
+-------------------------------------------------------------+
```

### UI States Checklist
- [ ] **Empty State:** Visual when zero data / first-time user.
- [ ] **Loading State:** Spinner / skeleton / disabled button during submission.
- [ ] **Error State:** Field error messages, alert banner for failure.
- [ ] **Success State:** Toast notification, redirect, or view update.

## Data notes
<!-- Fields, types, validations, defaults, sample payload. -->

## INVEST check
- [ ] Independent  - [ ] Negotiable  - [ ] Valuable  - [ ] Estimable  - [ ] Small  - [ ] Testable
