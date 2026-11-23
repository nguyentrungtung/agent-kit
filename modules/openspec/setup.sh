#!/usr/bin/env bash
# Runs inside the target project. Initialises OpenSpec with the agent-kit schema and config.
set -eu
lang="$(sed -n 's/^docs_language:[[:space:]]*\([a-z]*\).*/\1/p' .agent/project.yaml 2>/dev/null | head -n1)"
case "$lang" in vi) language="Vietnamese" ;; en|"") language="English" ;; *) language="$lang" ;; esac
[ -f openspec/config.yaml ] && sed -i.bak "s/{{DOCS_LANGUAGE}}/$language/" openspec/config.yaml && rm -f openspec/config.yaml.bak
if ! command -v npx >/dev/null 2>&1 && ! command -v openspec >/dev/null 2>&1; then
  echo "OpenSpec needs Node.js ≥ 20.19 — install Node, then run: .agent/scripts/kit-openspec init --tools ${KIT_OPENSPEC_TOOLS:-claude,codex,gemini,antigravity,dsh} --profile core --scope project --no-animation ." >&2
  exit 0
fi
.agent/scripts/kit-openspec init --tools "${KIT_OPENSPEC_TOOLS:-claude,codex,gemini,antigravity,dsh}" --profile core --scope project \
  --no-animation --no-copilot-cloud . </dev/null | grep -E '✔|skills|Config|rror' || true
