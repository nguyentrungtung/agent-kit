# Solution architecture — <system>
<!-- arc42-lite. Filled by kit-sa. Keep each section short; link details. Decisions → docs/adr/. -->

## 1. Goals & constraints
| Goal (from BA) | Constraint (tech, legal, budget, team, deadline) |
|---|---|

## 2. Quality scenarios (ranked)
| # | Attribute | Scenario (stimulus → response) | Measure |
|---|---|---|---|
| Q1 | Performance | 500 concurrent users place orders at peak | p95 < 800 ms, error rate < 0.1% |
| Q2 | Availability | one app node dies | no user-visible outage; RTO 15 min, RPO 5 min |

## 3. Context (C4 level 1)
```mermaid
C4Context
  title System context
  Person(customer, "Customer", "Places orders")
  System(sys, "Order system", "This system")
  System_Ext(pay, "Payment gateway")
  System_Ext(mail, "Email service")
  Rel(customer, sys, "Uses", "HTTPS")
  Rel(sys, pay, "Authorizes payments", "HTTPS/JSON")
  Rel(sys, mail, "Sends notifications", "SMTP/API")
```

## 4. Solution strategy
<!-- 5–8 bullets: architecture style, key technologies, how top scenarios are met. Link options/*.md and ADRs. -->

## 5. Containers (C4 level 2)
```mermaid
C4Container
  title Containers
  Person(customer, "Customer")
  System_Boundary(b, "Order system") {
    Container(web, "Web app", "React", "UI")
    Container(api, "API", "Spring Boot / Laravel / …", "Business logic")
    ContainerDb(db, "Database", "PostgreSQL", "Orders, customers")
    ContainerQueue(q, "Queue", "RabbitMQ", "Async jobs")
    Container(cache, "Cache", "Redis", "Sessions, hot reads")
  }
  Rel(customer, web, "Uses", "HTTPS")
  Rel(web, api, "Calls", "HTTPS/JSON")
  Rel(api, db, "Reads/writes", "SQL")
  Rel(api, q, "Publishes", "AMQP")
  Rel(api, cache, "Caches", "RESP")
```
| Container | Responsibility | Tech | Owns data | Scales by |
|---|---|---|---|---|

## 6. Modules & boundaries
| Module | Responsibility | May depend on | Enforced by |
|---|---|---|---|

## 7. Runtime scenarios
<!-- sequence diagrams for the 2–3 most important / risky flows, incl. failure paths -->

## 8. Deployment
```mermaid
C4Deployment
  title Production
  Deployment_Node(cloud, "Cloud / VPS", "region") {
    Deployment_Node(lb, "Load balancer / Ingress") {
      Container(proxy, "Reverse proxy", "Nginx/Traefik", "TLS termination")
    }
    Deployment_Node(app, "App nodes x2", "Docker") {
      Container(api, "API", "container")
    }
    Deployment_Node(dbn, "Managed DB", "PostgreSQL HA") {
      ContainerDb(db, "Database")
    }
  }
  Rel(proxy, api, "HTTP")
  Rel(api, db, "SQL/TLS")
```
| Env | Purpose | Hosting | Data | Deploy trigger |
|---|---|---|---|---|
| local | dev | docker compose | synthetic | — |
| staging | QA/UAT | | anonymised | merge to develop |
| prod | users | | real | release tag + approval |

## 9. Cross-cutting concepts
Security (authN/Z, secrets, zones) · Observability (logs, metrics, traces, SLOs, alerts) · Data (backup, retention, migration) ·
Resilience (timeouts, retries, circuit breakers, idempotency) · Configuration · i18n.

## 10. Decisions
| ADR | Decision | Status |
|---|---|---|

## 11. Risks & technical debt
| Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|
