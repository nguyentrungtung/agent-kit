# Sourced by kit-doctor (ok, bad, meh, cfg in scope)
if command -v codegraph >/dev/null 2>&1; then
  if [ -d .codegraph ]; then ok "codegraph index present"; else meh "codegraph installed but not initialised — run: codegraph init"; fi
else meh "codegraph not installed — npm install -g @colbymchenry/codegraph"; fi
return 0
