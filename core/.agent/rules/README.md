# Rules — what the agent must follow, and what enforces it

| Folder | Content | Who edits |
|---|---|---|
| `core/` | Rules for every project (git, security, testing, errors, logging, API, database) | kit (upgrade) / human |
| `stack/` | Community standard of each language/framework in this repo (installed by `kit init`) | kit / human |
| `project/` | Rules specific to THIS project (domain invariants, naming, module boundaries) | human + agent via ADR |

Priority when rules conflict: `project/` > `stack/` > `core/`. A tool (formatter, linter, arch test, CI) beats any text.

Every rule should name what enforces it. A rule enforced by nothing is a review item — turn important ones into a test.
Changing a rule (especially relaxing one) needs an ADR (`kit-adr`). Agents propose; humans approve (edits here ask for confirmation).
