#!/usr/bin/env bash
# Regression tests for kit behaviours that broke once (no network, no tool installs).
#   1. kit upgrade from < 0.11 keeps a customised shared skeleton when skeletons/<framework>/ is created
#   2. project CI "Task workflow gates": verifies tasks a PR finishes, skips tasks already finished on the base branch
# Usage: tests/regressions.sh [workdir]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; KIT="$ROOT/kit"
WORK="${1:-$(mktemp -d)}"; mkdir -p "$WORK"
export GIT_AUTHOR_NAME=kit GIT_AUTHOR_EMAIL=kit@example.invalid GIT_COMMITTER_NAME=kit GIT_COMMITTER_EMAIL=kit@example.invalid
fail=0
check() { if eval "$2"; then printf '  ok   %s\n' "$1"; else printf '  FAIL %s\n' "$1"; fail=$((fail+1)); fi; }
sha() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

# ---------------------------------------------------------------- 1. upgrade keeps customised skeletons
old_layout() { # turn a fresh Laravel install into the < 0.11 layout: framework skeleton in the shared folder, recorded in the manifest
  local d="$1" sk=".agent/stack/php/skeletons" f
  rm -rf "$d/$sk/laravel"
  for f in modular.txt layered.txt deptrac-modular.yaml; do cp "$ROOT/stacks/php/frameworks/laravel/skeletons/$f" "$d/$sk/$f"; done
  { grep -v " $sk/" "$d/.agent/kit.manifest"
    for f in modular.txt layered.txt deptrac-modular.yaml; do printf '%s  %s\n' "$(sha "$d/$sk/$f")" "$sk/$f"; done; } > "$d/m.tmp"
  mv "$d/m.tmp" "$d/.agent/kit.manifest"
}
laravel_project() { # laravel_project <dir> <customise:0|1>
  local d="$1"; mkdir -p "$d"
  (cd "$d" && git init -q && printf '{"require":{"laravel/framework":"^11"}}\n' > composer.json && touch artisan)
  "$KIT" init "$d" --preset app --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1
  old_layout "$d"
  [ "$2" = 1 ] && echo 'app/Custom/{{Module}}/   # USER EDIT' >> "$d/.agent/stack/php/skeletons/modular.txt"
  (cd "$d" && git add -A && git commit -qm "chore: kit 0.10 layout" --no-verify)
}
printf '\n== upgrade from < 0.11 keeps a customised skeleton\n'
d="$WORK/up-custom"; laravel_project "$d" 1
"$KIT" upgrade "$d" --allow-dirty >"$d.up1.log" 2>&1
sub="$d/.agent/stack/php/skeletons/laravel/modular.txt"
check "user edit carried into skeletons/laravel/"   "grep -q 'USER EDIT' '$sub'"
check "kit version offered as .kit-new"            "[ -f '$sub.kit-new' ]"
out="$(cd "$d" && .agent/scripts/kit-new module billing)"
check "kit-new module uses the customised skeleton" "printf '%s\n' \"\$out\" | grep -q 'app/Custom/Billing/'"
(cd "$d" && git add -A && git commit -qm "chore: upgrade" --no-verify)
"$KIT" upgrade "$d" --allow-dirty >"$d.up2.log" 2>&1
check "second upgrade keeps the edit"               "grep -q 'USER EDIT' '$sub'"

printf '\n== upgrade from < 0.11 without edits takes the shipped skeleton\n'
d="$WORK/up-clean"; laravel_project "$d" 0
"$KIT" upgrade "$d" --allow-dirty >"$d.up1.log" 2>&1
sub="$d/.agent/stack/php/skeletons/laravel/modular.txt"
check "skeletons/laravel/ is kit's file"            "cmp -s '$sub' '$ROOT/stacks/php/frameworks/laravel/skeletons/modular.txt'"
check "no .kit-new"                                 "[ ! -e '$sub.kit-new' ]"

# ---------------------------------------------------------------- 2. CI task gate scope
printf '\n== CI task gate: verify tasks this PR finishes, skip tasks finished on the base branch\n'
step_script() { # the run: block of the "Task workflow gates" step, with kit-task verify stubbed
  ruby -ryaml -e 'y = YAML.load_file(ARGV[0]); s = y["jobs"]["quality"]["steps"].find { |x| x["name"].to_s.start_with?("Task workflow gates") }; puts s["run"]' \
    "$ROOT/core/.github/workflows/ci.yml" | sed 's#KIT_BASE_REF="origin/$BASE_REF" .agent/scripts/kit-task verify "$t"#echo "VERIFY $t"#'
}
r="$WORK/ci"; rm -rf "$r" "$r.git"; mkdir -p "$r/.agent/tasks"
step_script > "$WORK/step.sh"
(
  cd "$r" && git init -q -b develop
  printf -- '---\nstatus: review\n---\n' > .agent/tasks/TASK-001-old.md
  printf -- '---\nstatus: todo\n---\n'   > .agent/tasks/TASK-002-new.md
  git add -A && git commit -qm init
  git clone -q --bare . "$r.git" && git remote add origin "$r.git" && git fetch -q
  git checkout -q -b chore/plan
  mkdir -p .agent/tasks/archive/2026-11 && git mv .agent/tasks/TASK-001-old.md .agent/tasks/archive/2026-11/
  sed -i.bak 's/review/done/' .agent/tasks/archive/2026-11/TASK-001-old.md && sed -i.bak 's/todo/review/' .agent/tasks/TASK-002-new.md
  rm -f .agent/tasks/*.bak .agent/tasks/archive/2026-11/*.bak && git commit -qam "chore: move"
)
out="$(cd "$r" && HEAD_REF=chore/plan BASE_REF=develop bash "$WORK/step.sh" 2>&1 || true)"
check "task finished by this PR is verified"        "printf '%s\n' \"\$out\" | grep -q 'VERIFY TASK-002'"
check "task archived after its own PR is skipped"   "! printf '%s\n' \"\$out\" | grep -q 'VERIFY TASK-001'"
rc=0; out="$(cd "$r" && HEAD_REF=feature/no-task BASE_REF=develop bash "$WORK/step.sh" 2>&1)" || rc=$?
check "code branch without TASK-NNN fails"          "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q 'has no TASK-NNN'"
out="$(cd "$r" && HEAD_REF=release/1.0 BASE_REF=develop bash "$WORK/step.sh" 2>&1 || true)"
check "release branch verifies nothing"            "! printf '%s\n' \"\$out\" | grep -q 'VERIFY'"

printf '\n%d failure(s) — workdir %s\n' "$fail" "$WORK"
[ $fail -eq 0 ]
