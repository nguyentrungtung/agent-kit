# Sourced by kit-doctor (ok, bad, meh, cfg in scope)
for t in dbt sqlfluff; do
  inenv=0; for e in ./.venv/bin/$t ./*/.venv/bin/$t; do [ -x "$e" ] && inenv=1; done
  if command -v "$t" >/dev/null 2>&1 || [ $inenv -eq 1 ]; then ok "$t available"
  elif grep -q "^cmd_[a-z_]*:.*\b$t\b" "$KIT_CFG"; then meh "$t not installed — pip install dbt-core dbt-duckdb sqlfluff (in a venv)"; fi
done
if [ -d openspec/schemas/data-flow ]; then ok "OpenSpec data-flow schema present"; fi
return 0
