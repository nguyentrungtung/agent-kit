# Modules & allowed dependencies
<!-- Owned by kit-sa (§3b). One row per module. This is a RULE file: agents must not add a module or a dependency
     without updating this table (and the ADR when boundaries change).
     - Path: backend module folder, repo-relative (kit-trace warns when folders on disk and this table drift apart).
     - Frontend: the matching feature folder (1:1 with the backend module when it has UI), or "—".
     - Enforced by: the arch test that fails on a forbidden dependency (deptrac.yaml layers, .dependency-cruiser.cjs rule,
       ArchitectureTest / Spring Modulith, import-linter contract, depguard). "—" = not enforced yet → that is a risk. -->

| Module | Path | Frontend | Type | Responsibility (one sentence) | Owns data | May depend on | Public API | Enforced by |
|---|---|---|---|---|---|---|---|---|
| <name> | <src/modules/name> | <frontend/src/features/name> | core / supporting / generic | | <tables> | <modules> | <facade / index.ts / events> | <tool + rule name> |

## Rules
- A module never reads or writes another module's tables — call its public API or react to its events.
- Dependencies are acyclic; a new arrow needs this table updated in the same PR (reviewed by the human).
- Frontend features import other features only through their `index.ts`; shared UI lives in `shared/` (see project-structure.md).
