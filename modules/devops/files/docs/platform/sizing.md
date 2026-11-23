# Infrastructure sizing & cost
<!-- kit-sa: derive from BA volumes. Show the arithmetic so it can be re-checked. -->

## Load model
| Metric | Value | Source / assumption |
|---|---|---|
| Users total / daily active / peak concurrent | | |
| Peak requests per second | | DAU × actions/day × peak factor / 86 400 |
| Data growth per month | | rows × row size |
| Retention | | |

## Per environment
| Env | Container | Replicas | vCPU | RAM | Storage | Notes |
|---|---|---|---|---|---|---|

## Monthly cost estimate
| Item | Option A | Option B | Notes |
|---|---|---|---|
| Compute | | | |
| Database (HA, backups) | | | |
| Storage / bandwidth | | | |
| Observability | | | |
| **Total** | | | |

## Scaling triggers
| Signal | Threshold | Action |
|---|---|---|
| CPU p95 | > 70% for 15 min | add a replica |
