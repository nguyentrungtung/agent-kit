---
name: kit-adr
description: Record an architecture/technical decision as an ADR in docs/adr and index it in .agent/memory/DECISIONS.md. Use whenever choosing a library, pattern, schema, protocol, or accepting a trade-off.
---
# kit-adr

1. Next number: highest `docs/adr/NNNN-*.md` + 1. File: `docs/adr/NNNN-short-title.md` from `0000-template.md`.
2. Fill: context (forces, constraints), ≥ 2 options with pros/cons, decision, consequences, **how it is enforced**
   (architecture test, lint rule, CI check — prefer enforceable over prose).
3. Append a row to `.agent/memory/DECISIONS.md`: `| ADR-NNNN | date | one-line decision | accepted |`.
4. If it supersedes an older ADR, set the old one's status to `superseded by ADR-NNNN`.
5. Link the ADR from the task file and, if structural, from `ARCHITECTURE.md`.
