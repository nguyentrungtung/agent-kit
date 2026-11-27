# Sourced by kit-doctor (ok, bad, meh, cfg in scope)
if [ -d openspec ]; then ok "openspec/ initialised"
else
  os_tools="$(sed -n 's/^harnesses:[[:space:]]*//p' .agent/kit.lock 2>/dev/null | head -n1 | tr -d ' \r')"
  [ -z "$os_tools" ] && os_tools="claude"
  [ "$os_tools" = "all" ] && os_tools="claude,codex,gemini,antigravity,dsh"
  meh "openspec/ missing — run: kit add openspec (or .agent/scripts/kit-openspec init --tools $os_tools --profile core --scope project .)"
fi
[ -f openspec/schemas/kit-flow/schema.yaml ] && ok "kit-flow schema present" || bad "openspec/schemas/kit-flow missing (kit add openspec)"
os_ver="$(cfg openspec_version 2.1.1)"
if command -v openspec >/dev/null 2>&1; then
  v="$(openspec --version 2>/dev/null || true)"
  if [ "$v" = "$os_ver" ]; then ok "openspec $v (pinned)"
  elif [ -n "$v" ]; then meh "openspec $v installed, project pins $os_ver — kit-openspec will use npx"
  else meh "openspec on PATH failed to report version (pins $os_ver) — kit-openspec will use npx"; fi
elif command -v npx >/dev/null 2>&1; then ok "openspec via npx (pinned $os_ver)"
else bad "OpenSpec needs Node.js ≥ 20.19 (no openspec/npx found)"; fi
return 0
