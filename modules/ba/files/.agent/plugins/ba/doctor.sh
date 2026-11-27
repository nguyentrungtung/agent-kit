# Sourced by kit-doctor (ok, bad, meh, cfg in scope)
if command -v mmdc >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then ok "diagram rendering available (mmdc/docker)"
else meh "no mmdc or docker — kit-run docs will skip diagram checks"; fi
return 0
