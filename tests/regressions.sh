#!/usr/bin/env bash
# Regression tests for kit behaviours that broke once (no network, no tool installs).
#   1. kit upgrade from < 0.11 keeps a customised shared skeleton when skeletons/<framework>/ is created
#   2. project CI "Task workflow gates": verifies tasks a PR finishes, skips tasks already finished on the base branch
# Usage: tests/regressions.sh [workdir]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; KIT="$ROOT/kit"
WORK="${1:-$(mktemp -d)}"; mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"   # absolute: cases cd around
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
check "template 2 enforces the checklist"           "printf '%s\n' \"\$out\" | grep -q 'tick every item of the checklist'"
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
check "deleted template line still enforces gates"  "printf '%s\n' \"\$out\" | grep -q 'tick every item of the checklist'"
out="$(cd "$d" && perl -0pi -e 's/^template: 2\n//m' .agent/tasks/_TEMPLATE.md && .agent/scripts/kit-task new "From custom template" >/dev/null \
  && grep -h '^template:' .agent/tasks/TASK-003-*.md)"
check "new task from a customised template is 2"    "[ \"\$out\" = 'template: 2' ]"
out="$(cd "$d" && perl -0pi -e 's/^- \[ \] [A-Z][^\n]*\n//mg' .agent/tasks/_TEMPLATE.md && .agent/scripts/kit-task new "Older template body" 2>&1 >/dev/null; grep -c '^- \[ \] ' .agent/tasks/TASK-004-*.md)"
check "checklist added when the template lacks it"  "printf '%s\n' \"\$out\" | tail -n1 | grep -qx 8"

printf '\n== a review goes stale when code changes after it; "Docs: none" accepts Markdown emphasis\n'
out="$(cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — by test" >/dev/null && mkdir -p src && echo 'export const x = 1;' > src/later.js \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "code after the review → stale"               "printf '%s\n' \"\$out\" | grep -q 'code changed after the last review'"
out="$(cd "$d" && git add -A && git commit -qm wip --no-verify && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — before unicode" >/dev/null && echo 'export const y = 2;' > 'src/tài-khoản.js' \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "a non-ASCII file name also makes it stale"   "printf '%s\n' \"\$out\" | grep -q 'code changed after the last review'"
rc=0; (cd "$d" && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — uncommitted" >/dev/null 2>&1) || rc=$?
check "review refused while code is uncommitted"   "[ $rc -ne 0 ]"
out="$(cd "$d" && git add -A && git commit -qm wip --no-verify && .agent/scripts/kit-task review "BLOCKER 0 · MAJOR 0 — re-reviewed" >/dev/null && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "re-recorded review is current"               "printf '%s\n' \"\$out\" | grep -q '6 code review recorded'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-001-*.md)" && perl -0pi -e 's/(## 7\. Result\n(?:<!--.*?-->\n)?)/$1- **Docs:** none — internal helper\n/s' "$f" \
  && { .agent/scripts/kit-task verify 2>&1 || true; })"
check "'- **Docs:** none' accepted"                 "printf '%s\n' \"\$out\" | grep -q 'living docs updated with the code'"

printf '\n== the checklist gate: every box ticked (any number); a missing standard dimension only warns\n'
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-002-*.md)" && perl -pi -e 's/^- \[ \] /- [x] /' "$f" && { .agent/scripts/kit-task verify TASK-002 2>&1 || true; })"
check "all boxes ticked → done"                    "printf '%s\n' \"\$out\" | grep -q '2 clarification checklist done'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-002-*.md)" && perl -pi -e 's/^- \[x\] Numbers.*$/- [x] Something unrelated/' "$f" && { .agent/scripts/kit-task verify TASK-002 2>&1 || true; })"
check "a replaced dimension only warns"            "printf '%s\n' \"\$out\" | grep -q 'not in the checklist: Numbers' && printf '%s\n' \"\$out\" | grep -q '2 clarification checklist done'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-002-*.md)" && perl -0pi -e 's/(- \[x\] Something unrelated\n)/$1- [ ] Task-specific: export format\n/' "$f" && { .agent/scripts/kit-task verify TASK-002 2>&1 || true; })"
check "an unticked task-specific item blocks"     "printf '%s\n' \"\$out\" | grep -q 'tick every item of the checklist'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-002-*.md)" && perl -0pi -e 's/(- \[ \] Task-specific: export format\n)/$1* [ ] star bullet left open\n/' "$f" && perl -0pi -e 's/- \[ \] Task-specific: export format\n/- [x] Task-specific: export format\n/' "$f" && { .agent/scripts/kit-task verify TASK-002 2>&1 || true; })"
check "an unticked '*' item blocks too"             "printf '%s\n' \"\$out\" | grep -q 'tick every item of the checklist'"
out="$(cd "$d" && f="$(ls .agent/tasks/TASK-002-*.md)" && perl -0pi -e 's/\* \[ \] star bullet left open\n/1. [x] numbered item done\n+ [x] plus item done\n/' "$f" && { .agent/scripts/kit-task verify TASK-002 2>&1 || true; })"
check "ticked '1.' and '+' items pass"              "printf '%s\n' \"\$out\" | grep -q '2 clarification checklist done'"

printf '\n== kit add fills an empty key in a CRLF project.yaml and keeps the CRLF ending\n'
c="$WORK/crlf"; fresh "$c"
(cd "$c" && git init -q && printf '{"name":"x","version":"1.0.0"}\n' > package.json)
"$KIT" init "$c" --stack node --modules none --yes --no-deps --no-setup --no-tools >"$c.log" 2>&1
perl -pi -e 's/^cmd_api:.*\n//; s/^(cmd_audit:.*)$/$1\ncmd_api:/' "$c/.agent/project.yaml" && perl -pi -e 's/\r?\n/\r\n/g' "$c/.agent/project.yaml"
"$KIT" add api --dir "$c" --yes >>"$c.log" 2>&1 || true
check "empty CRLF key filled"                        "grep -q \$'^cmd_api: npx .*\\r\$' \"\$c/.agent/project.yaml\""
check "key not duplicated"                           "[ \"\$(grep -c '^cmd_api:' \"\$c/.agent/project.yaml\")\" = 1 ]"

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
printf '```text\r\nUS-71 inside a CRLF fence\r\n```\r\nUS-72 after the closed fence\r\n' > "$t/docs/ba/crlf.md"
printf 'See US-73 before.\n~~~\nUS-74 in a fence that is never closed\n' > "$t/docs/ba/unclosed.md"
printf '```x``` is inline code, not a fence\nUS-75 after an inline span\n' > "$t/docs/ba/inline.md"
out="$(cd "$t" && git init -q && { .agent/scripts/kit-trace 2>&1 || true; })"
check "id inside a CRLF fence is ignored"           "! printf '%s\n' \"\$out\" | grep -q 'US-71 is referenced'"
check "id after a closed CRLF fence is checked"     "printf '%s\n' \"\$out\" | grep -q 'US-72 is referenced'"
check "an inline code span is not a fence"   "printf '%s\n' \"\$out\" | grep -q 'US-75 is referenced'"
check "unclosed fence masks to end of file"         "! printf '%s\n' \"\$out\" | grep -q 'US-74 is referenced' && printf '%s\n' \"\$out\" | grep -q 'US-73 is referenced'"
check "real rows with < and ... define their ids"   "! printf '%s\n' \"\$out\" | grep -qE 'BR-0[78] is referenced'"
check "a filled row with a placeholder Stories cell" "! printf '%s\n' \"\$out\" | grep -q 'FR-05 is referenced'"
check "template placeholder rows define nothing"    "printf '%s\n' \"\$out\" | grep -q 'BR-01 is referenced' && printf '%s\n' \"\$out\" | grep -q 'NFR-02 is referenced'"
check "first-column id outside docs/ba is checked"  "printf '%s\n' \"\$out\" | grep -q 'NFR-09 is referenced'"
check "'failed' / 'If …' count as negative paths"   "! printf '%s\n' \"\$out\" | grep -qE 'US-0[124]-x.md +story has no negative'"
check "a lone lower-case 'if' does not"             "printf '%s\n' \"\$out\" | grep -qE 'US-03-x.md +story has no negative'"

# ---------------------------------------------------------------- CodeRabbit switch + git provider
printf '\n== kit-review-bot: on/off edits only reviews.auto_review.enabled; GitLab remotes are recognised\n'
b="$WORK/bot"; fresh "$b"; mkdir -p "$b/.agent/scripts"
cp "$ROOT/core/.agent/scripts/lib.sh" "$ROOT/core/.agent/scripts/kit-review-bot" "$b/.agent/scripts/"
BOT="$b/.agent/scripts/kit-review-bot"
(cd "$b" && git init -q)
out="$(cd "$b" && "$BOT" status 2>&1)"
check "no file → not set here"                       "printf '%s\n' \"\$out\" | grep -q 'not set here'"
(cd "$b" && "$BOT" off >/dev/null 2>&1)
check "off creates the file with enabled: false"     "grep -q 'enabled: false' \"\$b/.coderabbit.yaml\""
out="$(cd "$b" && "$BOT" status 2>&1)"
check "status says off"                              "printf '%s\n' \"\$out\" | grep -q 'automatic review: off'"
(cd "$b" && "$BOT" on >/dev/null 2>&1)
out="$(cd "$b" && "$BOT" status 2>&1)"
check "on flips it back"                             "printf '%s\n' \"\$out\" | grep -q 'automatic review: on' && grep -q 'enabled: true' \"\$b/.coderabbit.yaml\""
printf '# my config\nlanguage: vi-VN\nreviews:\n  profile: chill\n  auto_review:\n    drafts: false\n    enabled: true   # keep\n  path_filters:\n    - "!dist/**"\nchat:\n  enabled: true\n' > "$b/.coderabbit.yaml"
(cd "$b" && "$BOT" off >/dev/null 2>&1)
check "other keys and comments are kept"             "grep -q 'language: vi-VN' \"\$b/.coderabbit.yaml\" && grep -q 'profile: chill' \"\$b/.coderabbit.yaml\" && grep -q '# my config' \"\$b/.coderabbit.yaml\" && grep -q 'drafts: false' \"\$b/.coderabbit.yaml\""
check "only auto_review.enabled changed"             "grep -q '^    enabled: false' \"\$b/.coderabbit.yaml\" && grep -q '^  enabled: true' \"\$b/.coderabbit.yaml\""
printf 'reviews:\n  profile: chill\n' > "$b/.coderabbit.yaml"; before="$(cat "$b/.coderabbit.yaml")"
rc=0; (cd "$b" && "$BOT" off >/dev/null 2>&1) || rc=$?
check "reviews: without auto_review is not rewritten" "[ $rc -ne 0 ] && [ \"\$(cat \"\$b/.coderabbit.yaml\")\" = \"\$before\" ]"
printf 'language: en\n' > "$b/.coderabbit.yaml"; (cd "$b" && "$BOT" off >/dev/null 2>&1)
check "no reviews: block → appended"                 "grep -q 'language: en' \"\$b/.coderabbit.yaml\" && grep -q '^    enabled: false' \"\$b/.coderabbit.yaml\""
prov() { (cd "$b" && git remote remove origin 2>/dev/null; git remote add origin "$1"; . .agent/scripts/lib.sh; git_provider); }
check "gitlab.com remote → gitlab"                   "[ \"\$(prov https://gitlab.com/acme/app.git)\" = gitlab ]"
check "github.com remote → github"                   "[ \"\$(prov git@github.com:acme/app.git)\" = github ]"
printf 'git_provider: gitlab   # self-hosted\n' > "$b/.agent/project.yaml"
check "git_provider in project.yaml wins"            "[ \"\$(prov https://git.corp.example/acme/app.git)\" = gitlab ]"

# ---------------------------------------------------------------- hook managers (Husky / lefthook / …) coexist
printf '\n== kit init --hooks: an existing hook manager keeps ownership and calls the kit through kit-hook\n'
hk() { # hk <dir> [init args…] — a git repo with package.json, then kit init; log in <dir>.log
  local dir="$1"; shift; fresh "$dir"
  (cd "$dir" && git init -q -b main && printf '{"name":"x","version":"1.0.0"}\n' > package.json)
  [ -z "${PRE:-}" ] || (cd "$dir" && eval "$PRE")
  "$KIT" init "$dir" --stack node --modules none --yes --no-deps --no-setup --no-tools "$@" >"$dir.log" 2>&1 || true
}
hp() { git -C "$1" config --get core.hooksPath 2>/dev/null || true; }
H="$WORK/hk-husky"
PRE='mkdir -p .husky && printf "echo existing-hook-ran >> hook-ran.log" > .husky/pre-commit' hk "$H"
check "husky found → core.hooksPath left unset"     "[ -z \"\$(hp \"\$H\")\" ]"
check "your husky command is kept"                  "grep -q 'existing-hook-ran' \"\$H/.husky/pre-commit\""
check "kit call appended to an existing hook"       "[ \"\$(grep -c 'kit-hook pre-commit' \"\$H/.husky/pre-commit\")\" = 1 ]"
check "commit-msg / pre-push hook files created"    "grep -q 'kit-hook commit-msg \"\$1\"' \"\$H/.husky/commit-msg\" && grep -q 'kit-hook pre-push \"\$@\"' \"\$H/.husky/pre-push\" && [ -x \"\$H/.husky/pre-push\" ]"
"$KIT" init "$H" --stack node --modules none --yes --no-deps --no-setup --no-tools >/dev/null 2>&1 || true
check "running init again does not duplicate"       "[ \"\$(grep -c 'kit-hook' \"\$H/.husky/pre-commit\")\" = 1 ]"
# simulate Husky being active, then prove the whole chain: protected branch, commit message, and the user's own hook
(cd "$H" && git config core.hooksPath .husky && git add -A && git -c core.hooksPath=/dev/null commit -qm "chore: base" && git branch develop)
rc=0; (cd "$H" && git commit -q --allow-empty -m "chore: on main" >/dev/null 2>&1) || rc=$?
check "chain blocks a commit on a protected branch" "[ $rc -ne 0 ]"
(cd "$H" && git checkout -q -b feature/TASK-001-x)
rc=0; out="$(cd "$H" && git commit -q --allow-empty -m "bad message" 2>&1)" || rc=$?
check "chain enforces Conventional Commits"         "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q 'Conventional Commits'"
rc=0; (cd "$H" && rm -f hook-ran.log && git commit -q --allow-empty -m "chore(TASK-001): fine" >/dev/null 2>&1) || rc=$?
check "good commit passes and your hook also ran"   "[ $rc -eq 0 ] && grep -q existing-hook-ran \"\$H/hook-ran.log\""
out="$(cd "$H" && .agent/scripts/kit-doctor 2>&1 || true)"
check "kit-doctor accepts the chained hooks"        "printf '%s\n' \"\$out\" | grep -q 'chained through your hook manager'"
rc=0; (cd "$H" && .agent/scripts/kit-hook nonsense >/dev/null 2>&1) || rc=$?
check "kit-hook rejects an unknown hook name"       "[ $rc -eq 2 ]"

H="$WORK/hk-lefthook"; PRE='printf "pre-commit:\n  commands: {}\n" > lefthook.yml' hk "$H"
check "lefthook found → hooksPath unset, howto shown" "[ -z \"\$(hp \"\$H\")\" ] && grep -q 'lefthook.yml' \"\$H.log\" && grep -q 'kit-hook pre-push' \"\$H.log\""
H="$WORK/hk-husky-kit"; PRE='mkdir -p .husky' hk "$H" --hooks kit
check "--hooks kit overrides (with a warning)"      "[ \"\$(hp \"\$H\")\" = .githooks ] && grep -q 'stop running' \"\$H.log\""
H="$WORK/hk-plain"; hk "$H"
check "no manager → kit owns hooks as before"       "[ \"\$(hp \"\$H\")\" = .githooks ]"
H="$WORK/hk-keep"; hk "$H" --hooks keep
check "--hooks keep on a plain repo prints the lines" "[ -z \"\$(hp \"\$H\")\" ] && grep -q 'kit-hook commit-msg' \"\$H.log\""
rc=0; "$KIT" init "$WORK/hk-bad" --hooks nonsense >/dev/null 2>&1 || rc=$?
check "--hooks rejects other values"                "[ $rc -ne 0 ]"

# ---------------------------------------------------------------- adopting an existing repo cleanly (lessons from a real GitLab data repo)
printf '\n== kit init in an existing repo: Git host, flow, hooks, configs and files the repo already has\n'
ad() { # ad <dir> "<setup shell>" [kit init args…] — an existing git repo (main), then kit init (no modules unless asked); log in <dir>.log
  local dir="$1" setup="$2"; shift 2; fresh "$dir"
  (cd "$dir" && git init -q -b main && eval "$setup")
  "$KIT" init "$dir" --yes --no-deps --no-setup --no-tools --modules none "$@" >"$dir.log" 2>&1 || true
}
commit_all() { (cd "$1" && git add -A && git -c core.hooksPath=/dev/null commit -qm "chore: base" --no-verify); }
yv() { sed -n "s/^$2:[[:space:]]*\([^ #]*\).*/\1/p" "$1/.agent/project.yaml" | head -n1; }

# --- Git host: a self-hosted GitLab whose URL does not say "gitlab", recognised by its pipeline file
A="$WORK/ad-gitlab"
ad "$A" 'printf "stages: [test]\nt:\n  script: [echo]\n" > .gitlab-ci.yml && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify && git remote add origin https://git.example.cloud/data/lakehouse.git && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node
check "pipeline file → git_provider: gitlab"        "[ \"\$(yv \"\$A\" git_provider)\" = gitlab ]"
check "no .github/ in a GitLab repo"                "[ ! -e \"\$A/.github\" ]"
check "MR + issue templates installed"              "[ -f \"\$A/.gitlab/merge_request_templates/Default.md\" ] && [ -f \"\$A/.gitlab/issue_templates/task.md\" ]"
check "your .gitlab-ci.yml is untouched"            "git -C \"\$A\" diff --quiet HEAD -- .gitlab-ci.yml && [ -z \"\$(git -C \"\$A\" status --porcelain .gitlab-ci.yml)\" ]"
check "runtime provider agrees"                     "[ \"\$(cd \"\$A\" && . .agent/scripts/lib.sh && git_provider)\" = gitlab ]"
A="$WORK/ad-github"; ad "$A" 'git remote add origin git@github.com:acme/app.git && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node
check "github remote → github files only"           "[ \"\$(yv \"\$A\" git_provider)\" = github ] && [ -f \"\$A/.github/workflows/ci.yml\" ] && [ ! -e \"\$A/.gitlab\" ]"
A="$WORK/ad-none"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node --provider none
check "--provider none installs no host files"      "[ \"\$(yv \"\$A\" git_provider)\" = none ] && [ ! -e \"\$A/.github\" ] && [ ! -e \"\$A/.gitlab\" ]"
rc=0; "$KIT" init "$WORK/ad-bad" --provider svn >/dev/null 2>&1 || rc=$?
check "--provider rejects other values"             "[ $rc -ne 0 ]"

# --- flow: trunk-based when an existing repo has no develop; gitflow when it has one or is brand new
A="$WORK/ad-trunk"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
check "existing repo without develop → trunk"       "[ \"\$(yv \"\$A\" develop_branch)\" = main ] && ! git -C \"\$A\" show-ref -q --verify refs/heads/develop"
commit_all "$A"; tip="$(git -C "$A" rev-parse main)"
(cd "$A" && .agent/scripts/kit-task new "Trunk task" >/dev/null && .agent/scripts/kit-task start TASK-001 >/dev/null 2>&1)
check "kit-task start branches from main"           "[ \"\$(git -C \"\$A\" rev-parse --abbrev-ref HEAD)\" = feature/TASK-001-trunk-task ] && [ \"\$(git -C \"\$A\" merge-base HEAD main)\" = \"$tip\" ]"
A="$WORK/ad-flow-develop"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify && git branch develop' --stack node
check "a develop branch → gitflow as before"        "[ \"\$(yv \"\$A\" develop_branch)\" = develop ]"
A="$WORK/ad-flow-new"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node
check "brand-new repo → gitflow"                    "[ \"\$(yv \"\$A\" develop_branch)\" = develop ]"
A="$WORK/ad-flow-force"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node --flow gitflow
check "--flow gitflow creates develop"              "git -C \"\$A\" show-ref -q --verify refs/heads/develop && [ \"\$(yv \"\$A\" develop_branch)\" = develop ]"

# --- hooks: a hand-written hook in .git/hooks is a hook setup too
A="$WORK/ad-rawhook"
ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && printf "#!/bin/sh\nexit 0\n" > .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg' --stack node
check "hand-written .git/hooks kept (hooksPath unset)" "[ -z \"\$(hp \"\$A\")\" ] && grep -q 'keeping your' \"\$A.log\" && [ -x \"\$A/.git/hooks/commit-msg\" ]"

# --- configs and files the repo already has are not duplicated
A="$WORK/ad-dup"
ad "$A" 'mkdir -p ingestion/docker platform/compose && printf "[project]\nname=\"i\"\n" > ingestion/pyproject.toml && printf "line-length = 99\n" > ruff.toml && printf "FROM python:3.12\n" > ingestion/docker/Dockerfile && printf "services:\n  app: {}\n" > platform/compose/core.yml' --stack python:ingestion --modules devops
check "root ruff.toml → no second ruff.toml in ingestion/" "[ ! -e \"\$A/ingestion/ruff.toml\" ] && grep -q 'not adding a second' \"\$A.log\""
check "own Dockerfile kept, no generic one added"    "[ ! -e \"\$A/ingestion/Dockerfile\" ] && grep -q 'generic Dockerfile is not added' \"\$A.log\""
check "own compose file (core.yml in compose/) → no compose.yaml generated" "[ ! -e \"\$A/compose.yaml\" ] && grep -q 'not generating a second compose.yaml' \"\$A.log\""
check "cmd_up / down / logs left empty"              "[ -z \"\$(yv \"\$A\" cmd_up)\" ] && [ -z \"\$(yv \"\$A\" cmd_down)\" ]"
A="$WORK/ad-nodup"; ad "$A" 'mkdir -p ingestion && printf "[project]\nname=\"i\"\n" > ingestion/pyproject.toml' --stack python:ingestion --modules devops
check "without them the kit's own files are added"   "[ -f \"\$A/ingestion/ruff.toml\" ] && [ -f \"\$A/ingestion/Dockerfile\" ] && [ -f \"\$A/compose.yaml\" ] && [ -n \"\$(yv \"\$A\" cmd_up)\" ]"
for pr in data app; do   # presets pick modules, so these two run kit init without --modules none
  A="$WORK/ad-perf-$pr"; fresh "$A"; (cd "$A" && git init -q -b main && printf '{"name":"x","version":"1"}\n' > package.json)
  "$KIT" init "$A" --yes --no-deps --no-setup --no-tools --stack node --preset "$pr" >"$A.log" 2>&1 || true
done
check "app preset: k6 perf smoke + cmd_perf"         "[ -f \"\$WORK/ad-perf-app/perf/smoke.js\" ] && grep -q '^cmd_perf:[[:space:]]*if ' \"\$WORK/ad-perf-app/.agent/project.yaml\""
check "data preset: no perf files, cmd_perf empty"   "[ ! -e \"\$WORK/ad-perf-data/perf\" ] && ! grep -q '^cmd_perf:[[:space:]]*if ' \"\$WORK/ad-perf-data/.agent/project.yaml\""

# --- the repo's own .gitignore may hide kit files: say so
A="$WORK/ad-ignored"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && printf "AGENTS.md\n.claude/\n" > .gitignore' --stack node
check "ignored kit files are reported at install"    "grep -q 'ignores kit files' \"\$A.log\""
out="$(cd "$A" && .agent/scripts/kit-doctor 2>&1 || true)"
check "kit-doctor reports them too"                  "printf '%s\n' \"\$out\" | grep -q 'ignores kit files'"

# --- kit-doctor: `uv run <tool>` is fine when uv exists; dbt --target ci needs a ci target
UB="$WORK/uvbin"; rm -rf "$UB"; mkdir -p "$UB"; printf '#!/bin/sh\nexit 0\n' > "$UB/uv"; chmod +x "$UB/uv"
A="$WORK/ad-doctor"; ad "$A" 'mkdir -p ingestion transform && printf "[project]\nname=\"i\"\n" > ingestion/pyproject.toml && touch ingestion/uv.lock && printf "name: t\n" > transform/dbt_project.yml && printf "t:\n  outputs:\n    prod:\n      type: trino\n" > transform/profiles.yml' --stack python:ingestion,dbt:transform
out="$(cd "$A" && PATH="$UB:$PATH" .agent/scripts/kit-doctor 2>&1 || true)"
check "uv run <tool>: only uv is checked"            "! printf '%s\n' \"\$out\" | grep -q \"'ruff'\""
check "dbt without a ci target is flagged"           "printf '%s\n' \"\$out\" | grep -q \"no 'ci' target in profiles.yml\""
printf "t:\n  outputs:\n    ci:\n      type: duckdb\n" > "$A/transform/profiles.yml"
out="$(cd "$A" && PATH="$UB:$PATH" .agent/scripts/kit-doctor 2>&1 || true)"
check "with a ci target it is not"                   "! printf '%s\n' \"\$out\" | grep -q \"no 'ci' target in profiles.yml\""

# ---------------------------------------------------------------- issue sync: GitLab (REST) and GitHub (gh) behind one interface
printf '\n== kit-task sync / pull: GitLab through its REST API (fake server), GitHub through gh (fake gh)\n'
issue_project() { # issue_project <dir> <provider> <remote-url> → a kit project on develop with git_provider set
  local dir="$1"; fresh "$dir"
  (cd "$dir" && git init -q -b main && printf '{"name":"x","version":"1.0.0"}\n' > package.json)
  "$KIT" init "$dir" --stack node --modules none --yes --no-deps --no-setup --no-tools >"$dir.log" 2>&1
  perl -pi -e "s/^git_provider:.*/git_provider: $2/" "$dir/.agent/project.yaml"
  (cd "$dir" && git add -A && git commit -qm "chore: init" --no-verify && git branch develop && git checkout -q develop && git remote add origin "$3")
}
rm -f "$WORK/gl.log" "$WORK/gl.port"
# output redirected: a server that kept the script's stdout open would hang `bash regressions.sh | grep …` forever if the script died early
python3 "$ROOT/tests/lib/fake-gitlab.py" "$WORK/gl.log" "$WORK/gl.port" >/dev/null 2>&1 & GLPID=$!
trap 'kill "$GLPID" 2>/dev/null || true' EXIT
for _ in $(seq 1 50); do [ -s "$WORK/gl.port" ] && break; sleep 0.1; done
GLP="$(cat "$WORK/gl.port" 2>/dev/null || echo 0)"
g="$WORK/glsync"; issue_project "$g" gitlab "http://127.0.0.1:$GLP/acme/app.git"
(cd "$g" && .agent/scripts/kit-task new "Alpha feature" --priority P1 >/dev/null)
gls() { (cd "$g" && GITLAB_TOKEN="${GLT:-secret-token}" .agent/scripts/kit-task "$@" 2>&1); }
gl() { jq -s -r "$1" "$WORK/gl.log"; }
rc=0; out="$(cd "$g" && env -u GITLAB_TOKEN -u GITLAB_PRIVATE_TOKEN .agent/scripts/kit-task sync 2>&1)" || rc=$?
check "no token → clear error, nothing sent"        "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q GITLAB_TOKEN && [ ! -s \"$WORK/gl.log\" ]"
out="$(GLT=wrong gls sync TASK-001 || true)"
check "a rejected token is reported"                "printf '%s\n' \"\$out\" | grep -q 'HTTP 401'"
: > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "issue created in the encoded project path"   "[ \"\$(gl '[.[]|select(.m==\"POST\" and (.p|endswith(\"/issues\")))|.p]|first')\" = '/api/v4/projects/acme%2Fapp/issues' ]"
check "title and labels sent"                       "[ \"\$(gl '[.[]|select(.m==\"POST\" and (.p|endswith(\"/issues\")))|.form]|first|[.title, (.labels|contains(\"status:todo\") and contains(\"priority:P1\"))]|@csv')\" = '\"[TASK-001] Alpha feature\",true' ]"
check "every request carried the token"             "[ \"\$(gl 'all(.[]; .token==\"secret-token\")')\" = true ]"
check "labels are created first"                    "[ \"\$(gl '[.[]|select(.p|endswith(\"/labels\"))]|length')\" -ge 15 ]"
check "number saved in .agent/tasks/.issues"        "grep -qx 'TASK-001=41' \"\$g/.agent/tasks/.issues\""
: > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "second sync updates, adding/removing status" "[ \"\$(gl '[.[]|select(.m==\"PUT\")|.form]|first|[(.add_labels|contains(\"status:todo\")), (.remove_labels|contains(\"status:done\")), (.remove_labels|contains(\"status:todo\"))]|@csv')\" = 'true,true,false' ]"
perl -pi -e 's/^status: todo/status: done/' "$g"/.agent/tasks/TASK-001-*.md; : > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "done → the GitLab issue is closed"           "[ \"\$(gl '[.[]|select(.form.state_event==\"close\")]|length')\" = 1 ]"
perl -pi -e 's/^status: done/status: todo/' "$g"/.agent/tasks/TASK-001-*.md; : > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "back to todo → it is reopened"               "[ \"\$(gl '[.[]|select(.form.state_event==\"reopen\")]|length')\" = 1 ]"
out="$(gls pull 7)"
check "pull creates a task from the issue"          "ls \"\$g\"/.agent/tasks/TASK-002-*.md >/dev/null 2>&1 && grep -q '^type: fix' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q '^priority: P1' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q '^issue: 7' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q 'Users cannot log in' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q '^Source: gitlab issue #7' \"\$g\"/.agent/tasks/TASK-002-*.md"
out="$(gls pull 7 || true)"
check "pulling the same issue twice is refused"     "printf '%s\n' \"\$out\" | grep -q 'already linked'"
kill "$GLPID" 2>/dev/null || true; wait "$GLPID" 2>/dev/null || true

# GitHub keeps working through gh: the calls are the ones kit-task made before the provider refactor
FB="$WORK/fakebin"; rm -rf "$FB"; mkdir -p "$FB"
cat > "$FB/gh" <<'GH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 $2" in
  "issue create") echo "https://github.com/acme/app/issues/12" ;;
  "issue view") if printf '%s' "$*" | grep -q 'json state'; then echo CLOSED; else printf '{"title":"T","body":"b","labels":[{"name":"bug"}]}\n'; fi ;;
esac
exit 0
GH
chmod +x "$FB/gh"
gh_="$WORK/ghsync"; issue_project "$gh_" github "https://github.com/acme/app.git"
(cd "$gh_" && .agent/scripts/kit-task new "Beta fix" --type fix >/dev/null)
export GH_LOG="$WORK/gh.log"; : > "$GH_LOG"
(cd "$gh_" && PATH="$FB:$PATH" .agent/scripts/kit-task sync TASK-001 >/dev/null 2>&1)
check "github create: same flags as before"         "grep -qx 'issue create --title \[TASK-001\] Beta fix --body-file .* --label status:todo --label type:fix --label priority:P2' \"\$GH_LOG\""
: > "$GH_LOG"; (cd "$gh_" && PATH="$FB:$PATH" .agent/scripts/kit-task sync-gh TASK-001 >/dev/null 2>&1)
check "github update: add/remove labels as before"  "grep -q 'issue edit 12 --title \[TASK-001\] Beta fix --body-file .* --add-label status:todo,type:fix,priority:P2 --remove-label status:in-progress,status:review,status:done,status:abandoned' \"\$GH_LOG\""
check "github: a closed issue is reopened (old name sync-gh works)" "grep -qx 'issue reopen 12' \"\$GH_LOG\""
unset GH_LOG

# ---------------------------------------------------------------- 2. CI gates (kit-ci) — one script behind GitHub Actions and GitLab CI
printf '\n== kit-ci task-gates: verify tasks this PR finishes, skip tasks finished on the base branch\n'
r="$WORK/ci"; rm -rf "$r" "$r.git"; mkdir -p "$r/.agent/tasks" "$r/.agent/scripts"
cp "$ROOT/core/.agent/scripts/kit-ci" "$ROOT/core/.agent/scripts/lib.sh" "$r/.agent/scripts/"
printf '#!/usr/bin/env bash\necho "VERIFY $2"\n' > "$r/.agent/scripts/kit-task"; chmod +x "$r/.agent/scripts/kit-task"
kci() { (cd "$r" && KIT_CI_EVENT=pr KIT_CI_BASE=develop KIT_CI_HEAD="$1" .agent/scripts/kit-ci "$2" 2>&1); }
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
out="$(kci chore/plan task-gates || true)"
check "task finished by this PR is verified"        "printf '%s\n' \"\$out\" | grep -q 'VERIFY TASK-002'"
check "task archived after its own PR is skipped"   "! printf '%s\n' \"\$out\" | grep -q 'VERIFY TASK-001'"
rc=0; out="$(kci feature/no-task task-gates)" || rc=$?
check "code branch without TASK-NNN fails"          "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q 'has no TASK-NNN'"
out="$(kci release/1.0 task-gates || true)"
check "release branch verifies nothing"            "! printf '%s\n' \"\$out\" | grep -q 'VERIFY'"
out="$(cd "$r" && KIT_CI_EVENT=push .agent/scripts/kit-ci task-gates 2>&1 || true)"
check "a plain push has no task gates"              "printf '%s\n' \"\$out\" | grep -q 'merge requests only\|pull / merge requests only'"

printf '\n== kit-ci guard: branch name and Conventional Commits (GitHub and GitLab variables are understood)\n'
printf '#!/usr/bin/env bash\nexit 0\n' > "$r/.agent/scripts/kit-secrets-scan"; cp "$r/.agent/scripts/kit-secrets-scan" "$r/.agent/scripts/kit-trace"; chmod +x "$r/.agent/scripts/kit-secrets-scan" "$r/.agent/scripts/kit-trace"
(cd "$r" && git checkout -q develop && git checkout -q -b feature/TASK-009-x && echo a > a.txt && git add -A && git commit -qm "bad subject here" --no-verify)
out="$(kci feature/TASK-009-x guard || true)"
check "a bad commit subject fails the guard"        "printf '%s\n' \"\$out\" | grep -q 'bad commit subject: bad subject here'"
out="$(kci wip/foo guard || true)"
check "a branch name outside <type>/ fails"         "printf '%s\n' \"\$out\" | grep -q \"must be <type>/TASK-NNN-slug\""
(cd "$r" && git commit -q --amend -m "feat(TASK-009): add a thing" --no-verify)
rc=0; out="$(kci feature/TASK-009-x guard)" || rc=$?
check "good branch + subject pass"                  "[ $rc -eq 0 ]"
rc=0; out="$(cd "$r" && GITLAB_CI=true CI_MERGE_REQUEST_IID=7 CI_MERGE_REQUEST_SOURCE_BRANCH_NAME=wip/gl CI_MERGE_REQUEST_TARGET_BRANCH_NAME=develop .agent/scripts/kit-ci guard 2>&1)" || rc=$?
check "GitLab MR variables are read"                "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q \"branch 'wip/gl'\""
rc=0; out="$(cd "$r" && GITHUB_ACTIONS=true GITHUB_EVENT_NAME=pull_request GITHUB_HEAD_REF=wip/gh GITHUB_BASE_REF=develop .agent/scripts/kit-ci guard 2>&1)" || rc=$?
check "GitHub PR variables are read"                "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q \"branch 'wip/gh'\""

printf '\n== GitLab pipeline: installed with the stack image and setup; your own .gitlab-ci.yml is never edited\n'
A="$WORK/gl-new"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node --provider gitlab
check "no pipeline yet → .gitlab-ci.yml is installed" "[ -f \"\$A/.gitlab-ci.yml\" ] && [ ! -e \"\$A/.gitlab-ci.kit.yml\" ]"
check "image and setup are filled in, no placeholder left" "grep -q 'image: node:22' \"\$A/.gitlab-ci.yml\" && grep -q -- '- corepack enable' \"\$A/.gitlab-ci.yml\" && ! grep -q '@@' \"\$A/.gitlab-ci.yml\""
check "all four jobs are defined (valid YAML)"      "ruby -ryaml -e 'd = YAML.load_file(ARGV[0]); exit(%w[kit-guard kit-quality kit-sast kit-deps].all? { |j| d.key?(j) } ? 0 : 1)' \"\$A/.gitlab-ci.yml\""
check "every gate goes through kit-ci"              "grep -q 'kit-ci guard' \"\$A/.gitlab-ci.yml\" && grep -q 'kit-ci task-gates' \"\$A/.gitlab-ci.yml\" && grep -q 'kit-ci api' \"\$A/.gitlab-ci.yml\""
commit_all "$A"; (cd "$A" && "$KIT" upgrade . --allow-dirty >"$A.up.log" 2>&1 || true)
check "upgrade keeps the pipeline stable"           "[ -z \"\$(git -C \"\$A\" status --porcelain)\" ] && [ ! -e \"\$A/.gitlab-ci.yml.kit-new\" ]"
A="$WORK/gl-own"; ad "$A" 'printf "stages: [test]\nmine:\n  script: [echo mine]\n" > .gitlab-ci.yml && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node
check "own pipeline untouched, kit's written beside it" "grep -q 'echo mine' \"\$A/.gitlab-ci.yml\" && ! grep -q kit-guard \"\$A/.gitlab-ci.yml\" && grep -q 'kit-guard' \"\$A/.gitlab-ci.kit.yml\" && grep -q 'local: .gitlab-ci.kit.yml' \"\$A.log\""
for stk in python go; do   # every stack resolves to a real image
  B="$WORK/gl-$stk"; ad "$B" 'printf "[project]\nname=\"x\"\n" > pyproject.toml; printf "module x\n" > go.mod' --stack $stk --provider gitlab
  check "$stk stack image in the pipeline"          "grep -qE '^  image: (python:3.12|golang:1.23)\$' \"\$B/.gitlab-ci.yml\""
done

printf '\n%d failure(s) — workdir %s\n' "$fail" "$WORK"
[ $fail -eq 0 ]
