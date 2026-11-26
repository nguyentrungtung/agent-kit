#!/usr/bin/env bash
# Runs inside the target project. Initialises OpenSpec with the agent-kit schema and config.
set -eu
lang="$(sed -n 's/^docs_language:[[:space:]]*\([a-z]*\).*/\1/p' .agent/project.yaml 2>/dev/null | head -n1)"
case "$lang" in vi) language="Vietnamese" ;; en|"") language="English" ;; *) language="$lang" ;; esac
[ -f openspec/config.yaml ] && sed -i.bak "s/{{DOCS_LANGUAGE}}/$language/" openspec/config.yaml && rm -f openspec/config.yaml.bak

harnesses="$(sed -n 's/^harnesses:[[:space:]]*//p' .agent/kit.lock 2>/dev/null | head -n1 | tr -d ' ')"
harnesses="${harnesses:-claude}"
if [ "$harnesses" = all ]; then
  tools="claude,codex,gemini,antigravity,dsh"
else
  tools=""
  IFS=',' read -r -a _hs <<< "$harnesses"
  for h in "${_hs[@]}"; do
    case "$h" in claude|gemini|dsh|codex|antigravity) tools="${tools:+$tools,}$h" ;; esac
  done
  tools="${tools:-claude}"
fi
tools="${KIT_OPENSPEC_TOOLS:-$tools}"
keep_dot_agents=0
case ",$tools," in *,codex,*|*,antigravity,*|*,all,*) keep_dot_agents=1 ;; esac

if ! command -v npx >/dev/null 2>&1 && ! command -v openspec >/dev/null 2>&1; then
  echo "OpenSpec needs Node.js ≥ 20.19 — install Node, then run: .agent/scripts/kit-openspec init --tools $tools --profile core --scope project --no-animation ." >&2
  exit 0
fi
.agent/scripts/kit-openspec init --tools "$tools" --profile core --scope project \
  --no-animation --no-copilot-cloud . </dev/null | grep -E '✔|skills|Config|rror' || true

rm -f .agent/skills/.openspec-target .agents/skills/.openspec-target
# OpenSpec installs canonical skills under .agents/skills/. Keep root clean by moving them into .agent/skills/.
if [ -d .agents/skills ] && [ ! -L .agents/skills ]; then
  mkdir -p .agent/skills
  for d in .agents/skills/openspec-*; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    rm -rf ".agent/skills/$n"
    mv "$d" ".agent/skills/$n"
  done
  if [ $keep_dot_agents -eq 1 ]; then
    rmdir .agents/skills 2>/dev/null && ln -s ../.agent/skills .agents/skills || true
  else
    rmdir .agents/skills 2>/dev/null || true
    rmdir .agents 2>/dev/null || true
  fi
fi

# Re-point .claude/skills/openspec-* symlinks to the canonical .agent/skills/ directory
if [ -d .claude/skills ]; then
  for f in .claude/skills/openspec-*; do
    [ -L "$f" ] || continue
    n="$(basename "$f")"
    if [ -d ".agent/skills/$n" ]; then
      rm -f "$f"
      ln -s "../../.agent/skills/$n" "$f"
    fi
  done
fi
