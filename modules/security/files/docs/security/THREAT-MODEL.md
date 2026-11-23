---
title: Threat model
status: draft
owner:
updated:
asvs_level: L2
---
# Threat model
<!-- kit-appsec. Living document: update when a trust boundary, asset, integration or personal-data flow changes. -->

## Scope & assets
| Asset | Sensitivity | Where |
|---|---|---|

## Data-flow diagram (trust boundaries)
```mermaid
flowchart LR
  user([User / browser])
  subgraph internet[Internet — untrusted]
    user
  end
  subgraph edge[Edge — TLS, WAF]
    lb[Load balancer]
  end
  subgraph app[App zone]
    api[API]
  end
  subgraph data[Data zone]
    db[(Database)]
  end
  ext[[Third-party API]]
  user -- HTTPS --> lb --> api --> db
  api -- HTTPS --> ext
```

## STRIDE
| ID | Element / flow | Threat (S/T/R/I/D/E) | Likelihood | Impact | Risk | Control | Status / owner |
|---|---|---|---|---|---|---|---|
| T-01 | api ← user | S: credential stuffing | M | H | High | rate limit + lockout + MFA for admins | planned |

## Abuse cases
-

## Accepted risks (named human + date required)
| ID | Risk | Why accepted | Who | Date | Review by |
|---|---|---|---|---|---|
