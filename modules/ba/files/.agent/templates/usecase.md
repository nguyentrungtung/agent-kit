---
id: UC-{{NUM}}
title: {{TITLE}}
status: draft               # draft | reviewed | approved
actors:
priority: Must              # MoSCoW
stories: []
rules: []
updated: {{DATE}}
---
# UC-{{NUM}} {{TITLE}}

| Field | Content |
|---|---|
| Goal | |
| Primary actor | |
| Secondary actors / systems | |
| Trigger | |
| Pre-conditions | |
| Post-conditions (success) | |
| Post-conditions (failure) | |
| Business rules | BR-.. |
| Frequency / volume | |

## Main flow
1.

## Alternative flows
- A1 (at step n):

## Exception flows
- E1 (at step n):

## Activity diagram
```mermaid
flowchart TD
  s([Start]) --> a[Step 1]
  a --> d{Decision?}
  d -- Yes --> b[Step 2]
  d -- No --> e[Exception E1]
  b --> z([End])
```

## Sequence (system interaction)
```mermaid
sequenceDiagram
  actor U as Actor
  participant S as System
  U->>S: request
  S-->>U: response
```

## Open questions
