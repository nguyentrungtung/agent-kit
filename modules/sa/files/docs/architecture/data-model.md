---
title: Application data model
status: draft
owner:
updated:
---
# Application data model
<!-- Owned by kit-datamodel / solution architect. Living: matches the migrations. ID strategy & multitenancy → ADRs. -->

## Decisions
| Topic | Decision | ADR |
|---|---|---|
| ID strategy | | |
| Multitenancy | | |
| Soft delete / audit | | |

## Ownership
| Table | Module (owner) | Aggregate root | Read by (via API/events) |
|---|---|---|---|

## ERD — <module>
```mermaid
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_LINE : contains
  CUSTOMER {
    bigint id PK
    uuid public_id UK
    string email UK
  }
  ORDER {
    bigint id PK
    uuid public_id UK
    bigint customer_id FK
    string status
    numeric total_amount
    timestamptz created_at
  }
  ORDER_LINE {
    bigint id PK
    bigint order_id FK
    string sku
    int quantity
  }
```

## Data dictionary
| Table.column | Type | Null | Constraint / index | Meaning | PII |
|---|---|---|---|---|---|
