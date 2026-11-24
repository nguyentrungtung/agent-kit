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
fresh() { rm -rf "$1" "$1".*; mkdir -p "$1"; }   # every case starts clean, so the script can re-run in the same workdir
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
  local d="$1"; fresh "$d"
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
check "shared slot given back to the php skeleton"  "cmp -s '$d/.agent/stack/php/skeletons/modular.txt' '$ROOT/stacks/php/skeletons/modular.txt'"
check "no lingering conflict on the shared file"    "[ ! -e '$d/.agent/stack/php/skeletons/modular.txt.kit-new' ]"

printf '\n== upgrade from an OLDER framework skeleton version (hash only in stacks/skeleton-hashes.txt)\n'
d="$WORK/up-oldver"; laravel_project "$d" 1
sk=".agent/stack/php/skeletons/modular.txt"; oldh="$(printf 'an older laravel skeleton\n' | { shasum -a 256 2>/dev/null || sha256sum; } | cut -d' ' -f1)"
{ grep -v " $sk\$" "$d/.agent/kit.manifest"; printf '%s  %s\n' "$oldh" "$sk"; } > "$d/m.tmp" && mv "$d/m.tmp" "$d/.agent/kit.manifest"
{ cat "$ROOT/stacks/skeleton-hashes.txt"; printf '%s  php/laravel/modular.txt\n' "$oldh"; } > "$WORK/hashes.txt"
KIT_SKELETON_HASHES="$WORK/hashes.txt" "$KIT" upgrade "$d" --allow-dirty >"$d.up1.log" 2>&1
check "edit migrated although kit's file changed since" "grep -q 'USER EDIT' '$d/.agent/stack/php/skeletons/laravel/modular.txt'"

printf '\n== inherited framework (java-gradle + spring from java-maven): older version found under the owning stack\n'
d="$WORK/up-gradle"; fresh "$d"
(cd "$d" && git init -q && printf 'plugins { java }\n' > build.gradle.kts)
"$KIT" init "$d" --stack java-gradle::spring --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1
sk=".agent/stack/java-gradle/skeletons"; rm -rf "$d/$sk/spring"
cp "$ROOT/stacks/java-maven/frameworks/spring/skeletons/modular.txt" "$d/$sk/modular.txt"; echo 'x/{{module}}/   # USER EDIT' >> "$d/$sk/modular.txt"
oldh="$(printf 'an older spring skeleton\n' | { shasum -a 256 2>/dev/null || sha256sum; } | cut -d' ' -f1)"
{ grep -v " $sk/" "$d/.agent/kit.manifest"; printf '%s  %s\n' "$oldh" "$sk/modular.txt"; } > "$d/m.tmp" && mv "$d/m.tmp" "$d/.agent/kit.manifest"
(cd "$d" && git add -A && git commit -qm "chore: 0.10 layout" --no-verify)
{ cat "$ROOT/stacks/skeleton-hashes.txt"; printf '%s  java-maven/spring/modular.txt\n' "$oldh"; } > "$WORK/hashes-gradle.txt"
KIT_SKELETON_HASHES="$WORK/hashes-gradle.txt" "$KIT" upgrade "$d" --allow-dirty >"$d.up1.log" 2>&1
check "gradle+spring edit migrated"                 "grep -q 'USER EDIT' '$d/$sk/spring/modular.txt'"

printf '\n== two frameworks on one stack (nestjs + react): the edited shared file was react'"'"'s → migrated once, no stale conflict\n'
d="$WORK/up-mono"; fresh "$d"
(cd "$d" && git init -q && mkdir -p backend frontend && printf '{"dependencies":{"@nestjs/core":"^10"}}\n' > backend/package.json \
  && printf '{"dependencies":{"react":"^18"}}\n' > frontend/package.json)
"$KIT" init "$d" --stack node:backend:nestjs,node:frontend:react --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1
sk=".agent/stack/node/skeletons"; rm -rf "$d/$sk/nestjs" "$d/$sk/react"
for n in modular.txt layered.txt; do cp "$ROOT/stacks/node/frameworks/react/skeletons/$n" "$d/$sk/$n"; done   # 0.10: last framework won the slot
{ grep -v " $sk/" "$d/.agent/kit.manifest"; for n in modular.txt layered.txt; do printf '%s  %s\n' "$(sha "$d/$sk/$n")" "$sk/$n"; done; } > "$d/m.tmp" && mv "$d/m.tmp" "$d/.agent/kit.manifest"
echo 'src/features/{{module}}/extra/   # USER EDIT' >> "$d/$sk/modular.txt"
(cd "$d" && git add -A && git commit -qm "chore: 0.10 layout" --no-verify)
"$KIT" upgrade "$d" --allow-dirty >"$d.up1.log" 2>&1
check "react got the user's edit"                   "grep -q 'USER EDIT' '$d/$sk/react/modular.txt'"
check "nestjs got its own shipped skeleton"         "cmp -s '$d/$sk/nestjs/modular.txt' '$ROOT/stacks/node/frameworks/nestjs/skeletons/modular.txt'"
check "shared slot is node's, no stale .kit-new"    "cmp -s '$d/$sk/modular.txt' '$ROOT/stacks/node/skeletons/modular.txt' && [ ! -e '$d/$sk/modular.txt.kit-new' ]"

printf '\n== stacks/skeleton-hashes.txt lists every current framework skeleton\n'
missing=""; for p in "$ROOT"/stacks/*/frameworks/*/skeletons/*; do
  [ -f "$p" ] || continue; key="$(printf '%s' "$p" | sed -E 's#^.*/stacks/([^/]+)/frameworks/([^/]+)/skeletons/#\1/\2/#')"
  grep -qx "$(sha "$p")  $key" "$ROOT/stacks/skeleton-hashes.txt" || missing="$missing $key"; done
check "no missing hash (run scripts/skeleton-hashes.sh)${missing:+ —$missing}" "[ -z '$missing' ]"

printf '\n== upgrade from < 0.11 without edits takes the shipped skeleton\n'
d="$WORK/up-clean"; laravel_project "$d" 0
"$KIT" upgrade "$d" --allow-dirty >"$d.up1.log" 2>&1
sub="$d/.agent/stack/php/skeletons/laravel/modular.txt"
check "skeletons/laravel/ is kit's file"            "cmp -s '$sub' '$ROOT/stacks/php/frameworks/laravel/skeletons/modular.txt'"
check "no .kit-new"                                 "[ ! -e '$sub.kit-new' ]"

printf '\n== upgrade from < 0.11: an edited STACK skeleton is not copied into a framework folder (react had none before)\n'
d="$WORK/up-react"; fresh "$d"
(cd "$d" && git init -q && printf '{"dependencies":{"react":"^18"}}\n' > package.json)
"$KIT" init "$d" --preset app --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1
rm -rf "$d/.agent/stack/node/skeletons/react"                 # 0.10: no react skeletons; shared = node's own, recorded in the manifest
grep -v ' .agent/stack/node/skeletons/react/' "$d/.agent/kit.manifest" > "$d/m.tmp" && mv "$d/m.tmp" "$d/.agent/kit.manifest"
echo 'src/edited/{{module}}/   # USER EDIT' >> "$d/.agent/stack/node/skeletons/modular.txt"
(cd "$d" && git add -A && git commit -qm "chore: 0.10 layout" --no-verify)
up="$("$KIT" upgrade "$d" --allow-dirty 2>&1)"
sub="$d/.agent/stack/node/skeletons/react/modular.txt"
check "react gets its own shipped skeleton"         "cmp -s '$sub' '$ROOT/stacks/node/frameworks/react/skeletons/modular.txt'"
check "the user is told the edit is not react's"    "printf '%s\n' \"\$up\" | grep -q \"is not react's skeleton\""
check "the edited shared skeleton is kept"          "grep -q 'USER EDIT' '$d/.agent/stack/node/skeletons/modular.txt'"

# ---------------------------------------------------------------- legacy task files
printf '\n== a task file from an older template is not blocked by the new checklist / review gates\n'
d="$WORK/legacy"; fresh "$d"
(cd "$d" && git init -q && printf '{"name":"x","version":"1.0.0"}\n' > package.json)
"$KIT" init "$d" --stack node --modules none --yes --no-deps --no-setup --no-tools >"$d.log" 2>&1
perl -pi -e 's/^kit_version:.*/kit_version: 0.10.0/' "$d/.agent/project.yaml"   # the project was installed with 0.10 …
out="$(cd "$d" && git add -A && git commit -qm "chore: init" --no-verify && git branch develop && git checkout -q develop \
  && .agent/scripts/kit-task new "Old task" >/dev/null && f="$(ls .agent/tasks/TASK-001-*.md)" \
  && perl -0pi -e 's/^template: 2\n//m; s/^- \[ \] [A-Z][^\n]*\n//mg; s/(## 2\. Clarifications\n)/$1None\n/' "$f" \
  && .agent/scripts/kit-task start TASK-001 >/dev/null 2>&1 \
  && perl -pi -e 's/^kit_version:.*/kit_version: 0.11.0/' .agent/project.yaml && git commit -qam "chore: upgrade kit to 0.11" --no-verify \
  && mkdir -p docs/notes && echo 'See US-99 (dangling id elsewhere in the repo).' > docs/notes/x.md \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "legacy §2 accepted without the checklist"    "printf '%s\n' \"\$out\" | grep -q 'legacy task file without checklist'"
check "legacy task not asked for a review record"   "! printf '%s\n' \"\$out\" | grep -q 'no code review recorded'"
check "legacy task not asked for a source link"     "! printf '%s\n' \"\$out\" | grep -q 'links no source'"
check "legacy task not blocked by assumption/docs"  "! printf '%s\n' \"\$out\" | grep -qE 'unconfirmed assumptions|no spec / living doc'"
check "legacy task not blocked by repo-wide trace"  "! printf '%s\n' \"\$out\" | grep -q 'traceability errors'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-001-*.md)" && perl -0pi -e 's/^(tags: .*\n)/$1template: 2\n/m' "$f" && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "template 2 enforces the checklist"           "printf '%s\n' \"\$out\" | grep -q 'tick every item of the ambiguity checklist'"
check "template 2 asks for a review record"         "printf '%s\n' \"\$out\" | grep -q 'no code review recorded'"
rc=0; (cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 1 — oops" >/dev/null 2>&1) || rc=$?
check "review summary needs fixed/open for non-zero" "[ $rc -ne 0 ]"
out="$(cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — fixed openspec delta, reopened nothing" >/dev/null \
  && .agent/scripts/kit-task checkpoint "Review: MAJOR 1 open (just a commit message)" >/dev/null 2>&1; { .agent/scripts/kit-task verify 2>&1 || true; })"
check "'openspec'/'reopen' words are not 'open'"     "printf '%s\n' \"\$out\" | grep -q '6 code review recorded'"
out="$(cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 2 open — later" >/dev/null; { .agent/scripts/kit-task verify 2>&1 || true; })"
check "an open MAJOR in the latest review blocks"   "printf '%s\n' \"\$out\" | grep -q 'open BLOCKER/MAJOR'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-001-*.md)" && perl -0pi -e 's/^(## Progress log\n(?:<!--.*?-->\n)?)/$1- 2026-01-01 10:00 — Review: BLOCKER 0 · MAJOR 0 — looks good\n/ms' "$f" \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "hand-written review line is not accepted"    "printf '%s\n' \"\$out\" | grep -q \"not written by 'kit-task review'\""

printf '\n== template 2 cannot be switched off by deleting the line; a customised _TEMPLATE.md still yields template 2\n'
out="$(cd "$d" && .agent/scripts/kit-task new "After the upgrade" >/dev/null && f="$(ls .agent/tasks/TASK-002-*.md)" \
  && perl -0pi -e 's/^template: 2\n//m' "$f" && { .agent/scripts/kit-task verify TASK-002 2>&1 || true; })"
check "deleted template line still enforces gates"  "printf '%s\n' \"\$out\" | grep -q 'tick every item of the ambiguity checklist'"
out="$(cd "$d" && perl -0pi -e 's/^template: 2\n//m' .agent/tasks/_TEMPLATE.md && .agent/scripts/kit-task new "From custom template" >/dev/null \
  && grep -h '^template:' .agent/tasks/TASK-003-*.md)"
check "new task from a customised template is 2"    "[ \"\$out\" = 'template: 2' ]"
out="$(cd "$d" && perl -0pi -e 's/^- \[ \] [A-Z][^\n]*\n//mg' .agent/tasks/_TEMPLATE.md && .agent/scripts/kit-task new "Older template body" 2>&1 >/dev/null; grep -c '^- \[ \] ' .agent/tasks/TASK-004-*.md)"
check "checklist added when the template lacks it"  "printf '%s\n' \"\$out\" | tail -n1 | grep -qx 8"

printf '\n== a review goes stale when code changes after it; "Docs: none" accepts Markdown emphasis\n'
out="$(cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — by test" >/dev/null && mkdir -p src && echo 'export const x = 1;' > src/later.js \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "code after the review → stale"               "printf '%s\n' \"\$out\" | grep -q 'code changed after the last review'"
out="$(cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — before unicode" >/dev/null && echo 'export const y = 2;' > 'src/tài-khoản.js' \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "a non-ASCII file name also makes it stale"   "printf '%s\n' \"\$out\" | grep -q 'code changed after the last review'"
out="$(cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — re-reviewed" >/dev/null && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "re-recorded review is current"               "printf '%s\n' \"\$out\" | grep -q '6 code review recorded'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-001-*.md)" && perl -0pi -e 's/(## 7\. Result\n(?:<!--.*?-->\n)?)/$1- **Docs:** none — internal helper\n/s' "$f" \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "'- **Docs:** none' accepted"                 "printf '%s\n' \"\$out\" | grep -q 'living docs updated with the code'"

printf '\n== kit-trace: placeholder rows, real rows with < and ..., ids outside docs/ba, negative-path wording\n'
t="$WORK/trace"; fresh "$t"; mkdir -p "$t/.agent/scripts" "$t/docs/ba/stories" "$t/docs/architecture"
cp "$ROOT/core/.agent/scripts/lib.sh" "$ROOT/core/.agent/scripts/kit-trace" "$t/.agent/scripts/"
cp "$ROOT/modules/ba/files/docs/ba/REQUIREMENTS.md" "$t/docs/ba/"
printf '| BR-07 | Quantity must be > 0 and < 100 (inclusive ...) |\n| BR-08 | Returns List<Order> sorted |\n' >> "$t/docs/ba/REQUIREMENTS.md"
printf '| FR-05 | WHEN a user submits an order, the system SHALL email a receipt. | Event-driven | Must | G1 | `<US-NN>` |\n' >> "$t/docs/ba/REQUIREMENTS.md"
printf 'See BR-07, BR-08, FR-05. Uses BR-01 and NFR-02.\n' > "$t/docs/ba/notes.md"
printf '| NFR-09 | Redis cache |\n' > "$t/docs/architecture/SOLUTION.md"
story() { printf -- '---\nuse_case:\n---\n# %s\n## Acceptance criteria\n- AC1 — %s\n' "$1" "$2" > "$t/docs/ba/stories/$1-x.md"; }
story US-01 "Given a card When paying Then the payment failed message is shown"
story US-02 "If the card is declined Then an error banner shows"
story US-03 "Given a user When opening Then the dashboard shows if data exists"
story US-04 "Given a viewer
- AC2 — If the user lacks permission Then a 403 page shows"
out="$(cd "$t" && git init -q && { .agent/scripts/kit-trace 2>&1 || true; })"
check "real rows with < and ... define their ids"   "! printf '%s\n' \"\$out\" | grep -qE 'BR-0[78] is referenced'"
check "a filled row with a placeholder Stories cell" "! printf '%s\n' \"\$out\" | grep -q 'FR-05 is referenced'"
check "template placeholder rows define nothing"    "printf '%s\n' \"\$out\" | grep -q 'BR-01 is referenced' && printf '%s\n' \"\$out\" | grep -q 'NFR-02 is referenced'"
check "first-column id outside docs/ba is checked"  "printf '%s\n' \"\$out\" | grep -q 'NFR-09 is referenced'"
check "'failed' / 'If …' count as negative paths"   "! printf '%s\n' \"\$out\" | grep -qE 'US-0[124]-x.md +story has no negative'"
check "a lone lower-case 'if' does not"             "printf '%s\n' \"\$out\" | grep -qE 'US-03-x.md +story has no negative'"

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
