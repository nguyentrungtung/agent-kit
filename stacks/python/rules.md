# Python rules (community standards)

Sources: **PEP 8** (style), **PEP 257** (docstrings), **PEP 484/526** (typing), Google Python Style Guide (docstrings).

| Rule | Enforced by |
|---|---|
| Formatting (Black-compatible), import sorting | `ruff format` / `ruff check` rule `I` |
| PEP 8 naming, docstrings, bugbear, bandit security | `ruff check` (`kit-run lint`) |
| Fully typed, `mypy --strict` | `mypy` (`kit-run typecheck`) |
| Layer / forbidden imports | import-linter (`kit-run arch`) |
| No known-vulnerable deps | `pip-audit` |

## Naming (PEP 8)
`snake_case` modules/functions/variables · `PascalCase` classes · `UPPER_SNAKE_CASE` constants · `_leading_underscore` internal ·
test files `test_<module>.py`.

## Language
- Type every function signature; use `X | None`, `list[int]` (PEP 604/585). No `Any` without reason.
- Data containers: `@dataclass(frozen=True, slots=True)` or Pydantic models at boundaries. No dicts-as-objects across modules.
- `pathlib.Path` not `os.path`; f-strings; context managers for resources; `enum.Enum`/`StrEnum` for closed sets.
- No mutable default arguments; no wildcard imports; no module-level side effects except constants.
- `Decimal` for money; timezone-aware `datetime` (UTC) only.

## Errors & logging
- Raise specific exceptions (custom hierarchy per domain); never bare `except:` or `except Exception: pass`.
- `raise ... from err` when translating. `logging.getLogger(__name__)` with structured extras; never print secrets/PII; no `print()` in app code.

## Security
- No `eval`/`exec`/`pickle` on untrusted data; `subprocess` without `shell=True`; parameterised SQL only; `secrets` module for tokens.

## Tests
- pytest, fixtures over setup methods, `parametrize` for tables of cases, no network (respx/responses), freeze time.
