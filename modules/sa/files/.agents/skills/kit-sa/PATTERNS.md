# kit-sa reference — patterns & algorithms (read on demand, from kit-sa §5b)

Rule: **a pattern needs a named problem from the requirements.** No problem in BA/NFR → no pattern. Every pattern chosen
goes into SOLUTION.md §7b with the problem it solves; project-wide ones get an ADR. Prefer the simplest row that fits.

## 1. Design patterns — problem → pattern → when NOT
| Problem in the requirements | Pattern | Do NOT use when |
|---|---|---|
| Business logic must not depend on DB/framework; many integrations | Hexagonal (ports & adapters) inside the module | Plain CRUD — a service + repository is enough |
| Data access behind an interface, testable services | Repository (+ Unit of Work / transaction per use case) | Reporting queries — use read models / SQL directly |
| Several interchangeable rules (pricing, shipping fee, tax, discount by customer type) | Strategy (+ registry/factory keyed by type) | Only 1–2 fixed variants — an `if` is clearer |
| Object lifecycle with allowed transitions (order, ticket, approval) | State machine (explicit transition table, guards, events) | Two states — a boolean / enum check |
| Combinable filters / eligibility rules | Specification | Fixed query — just write it |
| A step pipeline that varies (import, validation, checkout) | Chain of responsibility / pipeline | Steps never change |
| React to something without coupling modules | Domain events (in-process) → integration events (broker) | Caller needs the result synchronously |
| DB write + message must both happen | Transactional **Outbox** (+ idempotent consumer) | No broker / no async consumer |
| Multi-step business transaction across modules/services | **Saga** (orchestrated for clarity; compensations defined) | Single DB — use a local transaction |
| Reads very different from writes (dashboards, search) | CQRS-lite: separate read model / projection | Same shape for read and write |
| Full audit / time travel required by law | Event sourcing | Almost always otherwise — audit table is enough |
| Calls to an unreliable external system | Timeout + retry with backoff & jitter + circuit breaker + idempotency key | Internal in-process calls |
| Isolate a legacy/third-party model | Anti-corruption layer (adapter + translator) | Their model already matches ours |
| Long-running / heavy work triggered by a request | Async job queue + status polling / webhook | Work < ~1 s |
| Undo / audit of user commands | Command pattern | Simple writes |
| Frontend: server data | Query cache (TanStack Query/SWR) keyed by resource; no copy in a global store | — |
| Frontend: complex form / wizard | Form library + schema validation shared with the API types; state machine for multi-step | Single small form |

## 2. Algorithms & data structures — "core logic hotspots"
For each of the 3–5 hardest rules from BA (BRIEF › hand-off), fill SOLUTION.md §7b: input size, chosen approach, complexity,
correctness argument, how it is tested (property-based / table tests / golden files). Typical matches:

| Problem | Approach | Complexity / note |
|---|---|---|
| Money, tax, discounts, rounding | Integer minor units or decimal type; rounding rule (half-even/half-up) as a BR; never float | Test with boundary tables |
| Pricing / promotion rules that combine | Rule table + Strategy + explicit precedence; evaluate in a defined order | O(rules); test every precedence pair |
| Scheduling, booking, overlap detection | Interval sort + sweep line / interval tree; DB: exclusion constraint (Postgres `tstzrange` + GiST) | O(n log n); concurrency guarded by the DB |
| Resource allocation / assignment (staff, rooms, vehicles) | Greedy with priority queue for simple rules; Hungarian / min-cost flow for optimal; OR-Tools/ILP for many constraints | State optimal vs heuristic explicitly |
| Routing / shortest path / dependency order | Dijkstra / A*; topological sort (Kahn) for task/approval dependencies | Detect cycles → error |
| Inventory / stock reservation under concurrency | Atomic conditional update (`UPDATE … WHERE qty >= n`) or row lock; reservation with TTL | No read-modify-write in app code |
| Unique sequential numbers (invoice no.) | DB sequence per series / gap-free table with lock if law requires no gaps | Never `max()+1` |
| Idempotent processing (payments, webhooks) | Idempotency key table with unique constraint + stored response | Exactly-once effect, at-least-once delivery |
| Rate limiting / quotas | Token bucket / sliding window (Redis) | Per key; return 429 + Retry-After |
| Search, autocomplete, fuzzy match | DB full-text (Postgres `tsvector`, trigram) first; search engine only if NFR demands | Vietnamese: unaccent + normalisation |
| Deduplication / matching records | Normalise → blocking key → similarity (Levenshtein/Jaro-Winkler) → threshold + human review | Report precision/recall |
| Large exports / reports | Streaming / cursor pagination, async job, pre-aggregated tables | Memory O(page) |
| Recommendation / ranking (simple) | Weighted scoring with documented weights; A/B later | Explainable first |
| Hierarchies (org chart, categories) | Adjacency list + recursive CTE; closure table / ltree when reads dominate | Depth limits |
| Time zones, recurring events | Store UTC + IANA zone; RRULE (RFC 5545) library | Never hand-roll DST |

## 3. Module decomposition heuristics (kit-sa §3b)
1. Start from **business capabilities / bounded contexts** in the BA docs (nouns + verbs owned by one stakeholder group),
   never from technical layers ("controllers", "utils") or from screens.
2. One module **owns its data** (tables) — no other module writes them; others call its public API or react to its events.
3. High cohesion: things that change together for the same business reason live together. Check against the story map.
4. Low coupling: draw the dependency graph; it must be acyclic. A cycle → merge the modules or extract the shared concept.
5. Size: a module a developer understands in one sitting (≈ 1 aggregate cluster, 3–15 use cases). Too small = anaemic; too big = split by sub-domain.
6. Mark each module **core / supporting / generic** (DDD). Generic (auth, notifications, files) → buy/library first.
7. A future microservice = a module whose boundary has held for months, with independent scaling or team needs. Extract only then.
