---
name: kit-adr
description: Record an architecture/technical decision as an ADR in docs/adr and index it in .agent/memory/DECISIONS.md. Use whenever choosing a library, pattern, schema, protocol, or accepting a trade-off.
---
# kit-adr

1. Create the file: `.agent/scripts/kit-new adr "<title>" [--task TASK-NNN]` (numbers it, fills the template, indexes it in DECISIONS.md).
2. Fill: context (forces, constraints), ≥ 2 options with pros/cons, decision, consequences, **how it is enforced**
   (architecture test, lint rule, CI check — prefer enforceable over prose).
3. Set `status: accepted` once the human agrees, and update its row in `.agent/memory/DECISIONS.md`.
4. If it supersedes an older ADR, set the old one's status to `superseded by ADR-NNNN`.
5. Link the ADR from the task file and, if structural, from `ARCHITECTURE.md`.
