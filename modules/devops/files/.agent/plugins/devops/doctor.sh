# Sourced by kit-doctor (ok, bad, meh, cfg in scope)
if command -v docker >/dev/null 2>&1; then ok "docker available"; else meh "docker not installed — kit-run up/down and dockerised ops lint unavailable"; fi
for t in hadolint actionlint shellcheck; do command -v "$t" >/dev/null 2>&1 || meh "$t not installed — kit-ops-lint will use its Docker image"; done
if [ -f compose.yaml ]; then
  docker compose config -q >/dev/null 2>&1 && ok "compose.yaml valid" || meh "compose.yaml did not validate (docker compose config)"
fi
return 0
