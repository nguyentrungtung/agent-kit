# Process: <name>

## As-is
```mermaid
flowchart LR
  subgraph C[Customer]
    c1([Start: needs X]) --> c2[Sends request by email]
  end
  subgraph S[Sales staff]
    s1[Re-types request into Excel] --> s2{Stock available?}
    s2 -- Yes --> s3[Confirms by phone]
    s2 -- No --> s4[Waits for warehouse reply]
  end
  subgraph W[Warehouse]
    w1[Checks stock manually]
  end
  c2 --> s1
  s4 --> w1 --> s2
  s3 --> e([End])
  classDef pain fill:#fde2e2,stroke:#c0392b;
  class s1,s4 pain
```
Pain points: <!-- e.g. P1 re-typing (s1) ~10 min/request, P2 waiting for warehouse (s4) up to 1 day -->

## To-be
```mermaid
flowchart LR
  subgraph C[Customer]
    c1([Start]) --> c2[Submits order in portal]
  end
  subgraph SYS[Order system]
    y1{Stock reserved?} -- Yes --> y2[Create order, send confirmation]
    y1 -- No --> y3[Offer backorder date]
  end
  subgraph S[Sales staff]
    s1[Handles exceptions only]
  end
  c2 --> y1
  y3 --> s1
  y2 --> e([End])
```

## Steps (to-be)
| # | Actor | Step | Input | Output | Rule / exception |
|---|---|---|---|---|---|
| 1 | Customer | Submit order | cart | order draft | BR-01 min order value |

<!-- PlantUML alternative when lanes must be strict:
```plantuml
|Customer|
start
:Submit order;
|Order system|
if (Stock reserved?) then (yes)
  :Create order;
else (no)
  :Offer backorder;
endif
stop
```
-->
