#!/usr/bin/env bash
# Smoke test of the kit itself: kit init for every stack (+ frameworks) into temp dirs and check the result.
# Usage: tests/smoke.sh [workdir]   — no network, no tool installs (--no-deps --no-setup --no-tools)
# Env: KIT_TEST_JOBS=4 (parallel workers; 1 for sequential)
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)/kit"
WORK="${1:-$(mktemp -d)}"; mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"
export GIT_AUTHOR_NAME=kit GIT_AUTHOR_EMAIL=kit@example.invalid GIT_COMMITTER_NAME=kit GIT_COMMITTER_EMAIL=kit@example.invalid
JOBS="${KIT_TEST_JOBS:-4}"; case "$JOBS" in ''|*[!0-9]*) JOBS=4 ;; esac; [ "$JOBS" -ge 1 ] || JOBS=1
fail=0; n=0

check() { if eval "$2"; then printf '  ok   %s\n' "$1"; else printf '  FAIL %s\n' "$1"; fail=$((fail+1)); fi; }

case_() { # case_ <name> <preset> <setup-commands>
  local name="$1" preset="$2" setup="$3" d="$WORK/$1"
  rm -rf "$d"
  mkdir -p "$d" && (cd "$d" && eval "$setup") || { echo "  FAIL setup ($name)"; fail=$((fail+1)); return 1; }
  printf '\n== %s (preset %s)\n' "$name" "$preset"
  if ! "$KIT" init "$d" --preset "$preset" --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1; then echo "  FAIL kit init (see $d.log)"; fail=$((fail+1)); return; fi
  n=$((n+1))
  check "project.yaml has commands"        "grep -q '^cmd_lint:' '$d/.agent/project.yaml'"
  check "AGENTS.md playbooks rendered"      "grep -q '^- \`kit-task\`' '$d/AGENTS.md'"
  check "skills canonical + claude links"   "[ -f '$d/.agent/skills/kit-task/SKILL.md' ] && [ -L '$d/.claude/skills/kit-task' ]"
  check "claude imports root AGENTS.md"     "grep -q '^@\.\./AGENTS\.md' '$d/.claude/CLAUDE.md'"
  check "clean root layout"                 "[ ! -e '$d/.agents' ] && [ ! -e '$d/.gemini' ] && [ ! -e '$d/.githooks' ] && [ ! -e '$d/CLAUDE.md' ] && [ ! -e '$d/GLOSSARY.md' ]"
  check "manifest written"                  "[ -s '$d/.agent/kit.manifest' ]"
  check "scripts parse"                     "for f in '$d'/.agent/scripts/* '$d'/.agent/hooks/*.sh '$d'/.agent/githooks/*; do bash -n \"\$f\" || exit 1; done"
  check "no unresolved placeholders"        "! grep -rl '{{[A-Z_]*}}' '$d/.agent/project.yaml' '$d/AGENTS.md' '$d/.github/workflows' 2>/dev/null | grep -q ."
  check "ci has runtime setup"              "! grep -q '@@SETUP@@' '$d/.github/workflows/ci.yml'"
  check "kit-trace clean on fresh install"  "(cd '$d' && .agent/scripts/kit-trace >/dev/null 2>&1)"
}

SPECS=(
  'php-laravel|app|printf "{\"require\":{\"laravel/framework\":\"^11\"}}\n" > composer.json; touch artisan'
  'php-symfony|app|printf "{\"require\":{\"symfony/framework-bundle\":\"^7\"}}\n" > composer.json; touch symfony.lock'
  'java-spring|app|printf "<project><parent><artifactId>spring-boot-starter-parent</artifactId></parent></project>\n" > pom.xml'
  'gradle|app|printf "plugins { java }\n" > build.gradle.kts'
  'node-react|app|printf "{\"dependencies\":{\"react\":\"^18\"}}\n" > package.json'
  'node-nest|app|printf "{\"dependencies\":{\"@nestjs/core\":\"^10\"}}\n" > package.json'
  'python-fastapi|app|printf "fastapi\n" > requirements.txt'
  'python-airflow|data|printf "apache-airflow\n" > requirements.txt'
  'go|app|printf "module example.com/x\n\ngo 1.23\n" > go.mod'
  'rust|app|printf "[package]\nname=\"x\"\nversion=\"0.1.0\"\n" > Cargo.toml'
  'dotnet|app|touch App.csproj'
  'dbt|data|printf "name: x\nprofile: x\n" > dbt_project.yml'
  'monorepo|app|mkdir -p backend frontend; printf "<project><parent><artifactId>spring-boot-starter-parent</artifactId></parent></project>\n" > backend/pom.xml; printf "{\"dependencies\":{\"react\":\"^18\"}}\n" > frontend/package.json'
  'platform|platform|mkdir -p infra; printf "terraform {}\n" > infra/main.tf'
)

run_spec() {
  local idx="$1" spec="$2" name preset setup
  local fail=0 n=0
  name="${spec%%|*}"; spec="${spec#*|}"
  preset="${spec%%|*}"; setup="${spec#*|}"
  case_ "$name" "$preset" "$setup" >"$WORK/.out-$idx" 2>&1 || fail=$((fail+1))
  printf '%d %d\n' "$n" "$fail" > "$WORK/.cnt-$idx"
}

pids=(); active=()
for i in "${!SPECS[@]}"; do
  rm -f "$WORK/.out-$i" "$WORK/.cnt-$i"
  if [ "$JOBS" -le 1 ]; then
    run_spec "$i" "${SPECS[$i]}"
  else
    run_spec "$i" "${SPECS[$i]}" &
    pids+=($!); active+=($!)
    while [ ${#active[@]} -ge "$JOBS" ]; do
      wait "${active[0]}" || true
      active=("${active[@]:1}")
    done
  fi
done
wrc=0
[ ${#pids[@]} -eq 0 ] || for p in "${pids[@]}"; do wait "$p" || wrc=1; done

fail=0; n=0
for i in "${!SPECS[@]}"; do
  [ -f "$WORK/.out-$i" ] && cat "$WORK/.out-$i"
  if [ -f "$WORK/.cnt-$i" ]; then
    read -r cn cf < "$WORK/.cnt-$i"
    n=$((n+cn)); fail=$((fail+cf))
  else
    fail=$((fail+1))
  fi
  rm -f "$WORK/.out-$i" "$WORK/.cnt-$i"
done
[ $wrc -eq 0 ] || [ $fail -gt 0 ] || fail=1

d="$WORK/monorepo"; printf '\n== monorepo extras\n'
check "per-framework skeletons kept apart" "[ -f '$d/.agent/stack/node/skeletons/react/modular.txt' ]"
check "kit-new module uses the frontend skeleton" "(cd '$d' && .agent/scripts/kit-new module orders --component frontend | grep 'frontend/src/features/orders' >/dev/null)"

d="$WORK/harness-opt"; rm -rf "$d"; mkdir -p "$d"; (cd "$d" && touch app.py)
"$KIT" init "$d" --harness gemini,codex,antigravity --yes --no-deps --no-setup --no-tools >/dev/null 2>&1
check "multi-harness wires gemini context" "grep -q AGENTS.md '$d/.gemini/settings.json'"
check "multi-harness wires codex/antigravity skills" "[ -L '$d/.agents/skills' ]"

printf '\n%d project(s) installed, %d failure(s) — workdir %s\n' "$n" "$fail" "$WORK"
[ $fail -eq 0 ]
