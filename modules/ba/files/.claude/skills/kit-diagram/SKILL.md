---
name: kit-diagram
description: Draw correct, readable diagrams as code (Mermaid first, PlantUML when Mermaid can't express it, C4 for architecture) for BA and architecture docs — choose the right diagram type, follow notation conventions, validate rendering with kit-diagrams. Use whenever a document needs a flow, sequence, state, ERD, use case, swimlane process, C4 or deployment diagram.
---
# kit-diagram — diagrams as code

## Choose the diagram
| Question to answer | Diagram | Syntax |
|---|---|---|
| Who does what, in which order, across roles? | Swimlane activity (process as-is/to-be) | Mermaid `flowchart` + one `subgraph` per lane, or PlantUML activity with `|Lane|` |
| Which actors use which functions? | Use case | PlantUML `usecase` (Mermaid has no use-case type) |
| How do components/systems talk, incl. errors? | Sequence | Mermaid `sequenceDiagram` |
| What states can an object be in? | State machine | Mermaid `stateDiagram-v2` |
| What data exists and how is it related? | ERD | Mermaid `erDiagram` |
| What are the systems/containers/deployments? | C4 context / container / deployment | Mermaid `C4Context`/`C4Container`/`C4Deployment` or Structurizr DSL |
| How does a feature/epic break down? | Story map / mind map | Mermaid `mindmap` or table |
| When do things happen? | Timeline / Gantt | Mermaid `gantt` |

## Conventions
- Source lives in Markdown fences (```` ```mermaid ```` / ```` ```plantuml ````) next to the text that explains it. GitHub renders Mermaid natively.
- One diagram = one question. ≤ ~15 nodes / ~10 participants; split otherwise (overview + detail).
- Title + legend when colours/shapes carry meaning. Use real names from `GLOSSARY.md`, same IDs as requirements (US-03, BR-02).
- Sequence: show `alt`/`opt` for error and timeout paths; label messages with the operation (`POST /orders`), not "calls".
- Process: start/end events, decisions as diamonds with labelled exits (Yes/No), exceptions explicit; one lane per role or system.
- State: every state reachable, terminal states marked, transitions labelled `event [guard] / action`.
- ERD: cardinality on every relation, PK/FK marked, attribute types.
- Never invent architecture in BA diagrams — that is kit-sa's job.

## Validate & export
- `.agent/scripts/kit-diagrams check` — renders every block (mmdc / PlantUML, local or via Docker); fails on syntax errors.
- `.agent/scripts/kit-diagrams export` — writes SVGs to `docs/diagrams/out/` for slides/emails.
- For presentation-quality, interactive diagrams use the `archify` skill if available; keep the Markdown source as truth.
