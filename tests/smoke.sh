#!/usr/bin/env bash
# Smoke test of the kit itself: kit init for every stack (+ frameworks) into temp dirs and check the result.
# Usage: tests/smoke.sh [workdir]   — no network, no tool installs (--no-deps --no-setup --no-tools)
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)/kit"
WORK="${1:-$(mktemp -d)}"; mkdir -p "$WORK"
export GIT_AUTHOR_NAME=kit GIT_AUTHOR_EMAIL=kit@example.invalid GIT_COMMITTER_NAME=kit GIT_COMMITTER_EMAIL=kit@example.invalid
fail=0; n=0
check() { if eval "$2"; then printf '  ok   %s\n' "$1"; else printf '  FAIL %s\n' "$1"; fail=$((fail+1)); fi; }

case_() { # case_ <name> <preset> <setup-commands>
  local name="$1" preset="$2" setup="$3" d="$WORK/$1"
  mkdir -p "$d"; (cd "$d" && eval "$setup")
  printf '\n== %s (preset %s)\n' "$name" "$preset"
  if ! "$KIT" init "$d" --preset "$preset" --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1; then echo "  FAIL kit init (see $d.log)"; fail=$((fail+1)); return; fi
  n=$((n+1))
  check "project.yaml has commands"        "grep -q '^cmd_lint:' '$d/.agent/project.yaml'"
  check "AGENTS.md playbooks rendered"      "grep -q '^- \`kit-task\`' '$d/AGENTS.md'"
  check "skills canonical + claude links"   "[ -f '$d/.agents/skills/kit-task/SKILL.md' ] && [ -L '$d/.claude/skills/kit-task' ]"
  check "gemini context wired"              "grep -q AGENTS.md '$d/.gemini/settings.json'"
  check "manifest written"                  "[ -s '$d/.agent/kit.manifest' ]"
  check "scripts parse"                     "for f in '$d'/.agent/scripts/* '$d'/.agent/hooks/*.sh '$d'/.githooks/*; do bash -n \"\$f\" || exit 1; done"
  check "no unresolved placeholders"        "! grep -rl '{{[A-Z_]*}}' '$d/.agent/project.yaml' '$d/AGENTS.md' '$d/.github/workflows' 2>/dev/null | grep -q ."
  check "ci has runtime setup"              "! grep -q '@@SETUP@@' '$d/.github/workflows/ci.yml'"
}

case_ php-laravel app      'printf "{\"require\":{\"laravel/framework\":\"^11\"}}\n" > composer.json; touch artisan'
case_ php-symfony app      'printf "{\"require\":{\"symfony/framework-bundle\":\"^7\"}}\n" > composer.json; touch symfony.lock'
case_ java-spring app      'printf "<project><parent><artifactId>spring-boot-starter-parent</artifactId></parent></project>\n" > pom.xml'
case_ gradle app           'printf "plugins { java }\n" > build.gradle.kts'
case_ node-react app       'printf "{\"dependencies\":{\"react\":\"^18\"}}\n" > package.json'
case_ node-nest app        'printf "{\"dependencies\":{\"@nestjs/core\":\"^10\"}}\n" > package.json'
case_ python-fastapi app   'printf "fastapi\n" > requirements.txt'
case_ python-airflow data  'printf "apache-airflow\n" > requirements.txt'
case_ go app               'printf "module example.com/x\n\ngo 1.23\n" > go.mod'
case_ rust app             'printf "[package]\nname=\"x\"\nversion=\"0.1.0\"\n" > Cargo.toml'
case_ dotnet app           'touch App.csproj'
case_ dbt data             'printf "name: x\nprofile: x\n" > dbt_project.yml'
case_ monorepo app         'mkdir -p backend frontend; printf "<project><parent><artifactId>spring-boot-starter-parent</artifactId></parent></project>\n" > backend/pom.xml; printf "{\"dependencies\":{\"react\":\"^18\"}}\n" > frontend/package.json'
case_ platform platform    'mkdir -p infra; printf "terraform {}\n" > infra/main.tf'

printf '\n%d project(s) installed, %d failure(s) — workdir %s\n' "$n" "$fail" "$WORK"
[ $fail -eq 0 ]
