# Use cases: <area>

```plantuml
left to right direction
actor Customer
actor "Sales staff" as Sales
rectangle "Order system" {
  usecase "UC-01 Place order" as UC1
  usecase "UC-02 Track order" as UC2
  usecase "UC-03 Approve large order" as UC3
}
Customer --> UC1
Customer --> UC2
Sales --> UC3
UC1 .> UC3 : <<extend>> (amount > limit)
```

## UC-01 Place order
| Field | Content |
|---|---|
| Actors | Customer (primary), Payment gateway (secondary) |
| Goal | |
| Pre-conditions | |
| Trigger | |
| Main flow | 1. … 2. … |
| Alternative flows | 2a. … |
| Exception flows | E1. payment timeout → … |
| Post-conditions | success: … / failure: … |
| Business rules | BR-01, BR-04 |
| Related stories | US-01, US-02 |
