# Code intelligence (CodeGraph)

This repo is indexed by CodeGraph (`.codegraph/`, git-ignored). Use it BEFORE grep/find or opening files:
- MCP `codegraph_explore "<symbols or question>"` — verbatim source of relevant symbols + call paths + blast radius, in one call.
- CLI equivalents: `codegraph explore "<q>"`, `codegraph callers <symbol>`, `codegraph impact <symbol>`, `codegraph affected <files…>` (tests to run).
- Before changing a public function: run `impact` and list affected callers/tests in the task's Progress log.
- Index is refreshed automatically; if results look stale run `codegraph sync`.
