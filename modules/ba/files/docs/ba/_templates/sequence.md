# Sequence: <interaction>
<!-- Example ids (UC-01, US-04, BR-01, FR-01 …) are illustrations: replace them with real ones after copying. kit-trace skips ids
     inside fenced blocks (this whole Mermaid diagram), so it will NOT catch a leftover example id here — check them by hand. -->

```mermaid
sequenceDiagram
  autonumber
  actor U as Customer
  participant W as Web app
  participant API as Order API
  participant P as Payment gateway
  U->>W: Confirm cart
  W->>API: POST /orders (Idempotency-Key)
  API->>API: Validate (BR-01, BR-02)
  API->>P: Authorize payment
  alt authorized
    P-->>API: 200 authorized
    API-->>W: 201 Created (orderId)
    W-->>U: Show confirmation
  else declined
    P-->>API: 402 declined
    API-->>W: 422 Problem (payment-declined)
  else timeout (> 5 s)
    API-->>W: 202 Accepted (status: pending)
    Note over API,P: retry with backoff, reconcile job
  end
```
