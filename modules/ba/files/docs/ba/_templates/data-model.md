# Data model: <area>

```mermaid
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_LINE : contains
  PRODUCT ||--o{ ORDER_LINE : "is ordered in"
  CUSTOMER {
    uuid id PK
    string email UK
    string full_name
  }
  ORDER {
    uuid id PK
    uuid customer_id FK
    string status
    decimal total_amount
    timestamp created_at
  }
  ORDER_LINE {
    uuid id PK
    uuid order_id FK
    uuid product_id FK
    int quantity
  }
  PRODUCT {
    uuid id PK
    string sku UK
    decimal unit_price
  }
```

## Data dictionary
| Entity.field | Type | Required | Validation / format | Source | PII? | Example |
|---|---|---|---|---|---|---|
| Customer.email | string(254) | yes | RFC 5322, unique, lower-case | user input | yes | a@b.vn |
