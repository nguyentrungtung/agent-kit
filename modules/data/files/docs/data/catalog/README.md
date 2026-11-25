# Data catalog — which data to use

> Read this before writing SQL. Built and kept by the **kit-catalog** playbook. Column meanings: the dbt `.yml` files (`dbt docs`).
> Entities and keys: [entities.md](entities.md) · Metrics: [metrics.md](metrics.md) · Mandatory filters and gotchas: [rules.md](rules.md)

## Question → table
| Question (business words) | Use | Grain (one row = …) | Refresh | Owner | Notes |
|---|---|---|---|---|---|
| TODO: how many … per … per day? | `<schema>.<mart>` ([yml](../../../path/to/model.yml)) | TODO | TODO | TODO | |

## Do not use
| Table | Instead | Why |
|---|---|---|
| TODO: `<bronze/silver table>` | `<mart>` | e.g. not deduplicated, string-typed, history not current state |

## Layers
| Layer | Schema | For whom | Typed? | Notes |
|---|---|---|---|---|
| bronze / raw | TODO | pipelines only | TODO | as received from the source |
| silver / staging | TODO | data team | TODO | cleaned, 1:1 with the source |
| gold / marts | TODO | consumers | TODO | contracted (`docs/data/contracts/`) |

## Other documents
- TODO: indicator specifications, source descriptions, provider exchanges — link them, do not copy.
