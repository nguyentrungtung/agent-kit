# AGENTS.md — working ON agent-kit itself

> This file is for changing the kit's source. The rules agents follow inside an *installed* project live in `core/AGENTS.md`
> (copied into every project by `kit init`). Do not confuse the two.

## Layout
| Path | What |
|---|---|
| `kit`, `install.sh` | installer / upgrader CLI (`kit init`, `kit add`, `kit upgrade`) |
| `core/` | files every project gets (`.agent/` scripts, hooks, rules, templates; `AGENTS.md`; CI) |
| `modules/<m>/` | optional modules (`files/` copied as-is, `project.add` → project.yaml keys) |
| `stacks/<s>/`, `stacks/<s>/frameworks/<f>/` | per-language/framework configs, rules, skeletons |
| `tests/` | `smoke.sh` (offline install of every stack) · `regressions.sh` (offline, past bugs) · `e2e-workflow.sh` (network) |

## Before every push (in this order)
1. `bash -n` passes for every changed script; `tests/smoke.sh` and `tests/regressions.sh` pass; `tests/e2e-workflow.sh` when
   `core/.agent/scripts/kit-task`, `kit-new`, `kit-trace`, templates or the openspec module changed (needs network).
2. **Code review in a fresh context** — never only re-read your own diff in the same session:
   Claude Code `/code-review high main...HEAD` (or the `code-reviewer` sub-agent on `git diff main...HEAD`), walking
   `core/.agent/checklists/code-review.md` › *Change safety*. Fix every important finding, or state why not in the PR.
3. Changed a framework skeleton (`stacks/*/frameworks/*/skeletons/*`)? Run `scripts/skeleton-hashes.sh` and commit
   `stacks/skeleton-hashes.txt` (kit upgrade needs every shipped version; regressions.sh fails otherwise).
4. Every bug fixed gets a test in `tests/regressions.sh` (or smoke/e2e) that **fails without the fix** — try reverting once.
5. Think about **projects already installed**: `kit upgrade` keeps user-edited files (`.kit-new`), and new gates must not
   break in-flight work created by older versions (version the template, e.g. `template: 2`). Note breaking changes in README
   and bump `VERSION`.

## Pull requests
- Conventional Commits (`<type>(<scope>): <imperative subject>`), authored by the developer — no AI/vendor attribution.
- Answer an external reviewer (e.g. CodeRabbit) with **one** PR comment that lists each finding → fixed in `<sha>` / why not.
  Do not reply thread by thread through the API: every reply is a separate review and a separate e-mail.
- Never merge; the maintainer merges.
