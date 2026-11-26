#!/usr/bin/env bash
# Regression tests for kit behaviours that broke once (no network, no tool installs).
#   1. kit upgrade from < 0.11 keeps a customised shared skeleton when skeletons/<framework>/ is created
#   2. project CI "Task workflow gates": verifies tasks a PR finishes, skips tasks already finished on the base branch
# Usage: tests/regressions.sh [workdir]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; KIT="$ROOT/kit"
WORK="${1:-$(mktemp -d)}"; mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"   # absolute: cases cd around
export GIT_AUTHOR_NAME=kit GIT_AUTHOR_EMAIL=kit@example.invalid GIT_COMMITTER_NAME=kit GIT_COMMITTER_EMAIL=kit@example.invalid
export GIT_CONFIG_GLOBAL=/dev/null   # the developer's global git config (excludesFile, hooks…) must not hide or cause failures
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
commit_all "$A"; (cd "$A" && git checkout -q develop && git merge -q --ff-only main); dtip="$(git -C "$A" rev-parse develop)"
(cd "$A" && .agent/scripts/kit-task new "Null ngay tiep nhan" --type bug >/dev/null && .agent/scripts/kit-task start TASK-001 >/dev/null 2>&1)
(cd "$A" && .agent/scripts/kit-task new "测试任务" >/dev/null 2>&1)
check "a title with no Latin letters still gives a valid slug" "ls \"\$A\"/.agent/tasks/TASK-002-task.md >/dev/null 2>&1"
check "gitflow: --type bug → bugfix/TASK-… from develop" "case \"\$(git -C \"\$A\" rev-parse --abbrev-ref HEAD)\" in bugfix/TASK-001-null-ngay-tiep-nhan) true ;; *) false ;; esac && [ \"\$(git -C \"\$A\" merge-base HEAD develop)\" = \"$dtip\" ]"
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
check "init leaves --target ci gates empty without a ci target" "! grep -q -- '--target ci' \"\$A/.agent/project.yaml\""
sed -i.bak 's#^cmd_build:.*#cmd_build: (cd transform \&\& dbt docs generate --target ci)#' "$A/.agent/project.yaml" && rm -f "$A/.agent/project.yaml.bak"
out="$(cd "$A" && PATH="$UB:$PATH" .agent/scripts/kit-doctor 2>&1 || true)"
check "a hand-set --target ci without the target is flagged" "printf '%s\n' \"\$out\" | grep -q \"no 'ci' target in profiles.yml\""
printf "t:\n  outputs:\n    ci:\n      type: duckdb\n" > "$A/transform/profiles.yml"
out="$(cd "$A" && PATH="$UB:$PATH" .agent/scripts/kit-doctor 2>&1 || true)"
check "with a ci target it is not"                   "! printf '%s\n' \"\$out\" | grep -q \"no 'ci' target in profiles.yml\""
check "a new project keeps every gate (mypy + its config)" "grep -q '^cmd_typecheck:.*mypy' \"\$WORK/ad-nodup/.agent/project.yaml\" && [ -f \"\$WORK/ad-nodup/ingestion/mypy.ini\" ]"

# --- existing repo (has commits): the repo is the reference — gates only for tools it uses, commands from its CI
printf '\n== kit init --mode existing: gates for the tools the repo uses, commands from its CI, no duplicate ignores\n'
EX_SETUP='mkdir -p ingestion transform platform tools && touch ingestion/uv.lock \
  && printf "[project]\nname = \"i\"\ndependencies = [\n  \"dbt-core>=1.8\",\n]\n[project.optional-dependencies]\ndev = [\n  \"pytest>=8\",\n  \"ruff>=0.5\",\n]\n" > ingestion/pyproject.toml \
  && printf "name: t\nprofile: t\n" > transform/dbt_project.yml && printf "t:\n  outputs:\n    prod:\n      type: trino\n" > transform/profiles.yml \
  && printf "packages:\n  - package: dbt-labs/dbt_utils\n    version: 1.1.1\n" > transform/packages.yml \
  && printf "stages: [lint, test]\npytest:\n  stage: test\n  script:\n    - cd ingestion\n    - uv run pytest -q --ignore=tests/live\n" > .gitlab-ci.yml \
  && printf "**/.venv/\n**/__pycache__/\n.env\n.env.*\n**/.env\n!**/.env.example\ndocs/\n" > .gitignore && printf "A=1\n" > platform/.env.example \
  && printf "repos:\n  - repo: local\n    hooks: []\n" > .pre-commit-config.yaml \
  && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify'
A="$WORK/ex-data"; ad "$A" "$EX_SETUP" --stack python:ingestion,dbt:transform
check "project.yaml: no trailing spaces (trailing-whitespace hooks)" "! grep -nE ' +\$' \"\$A/.agent/project.yaml\" \"\$A/.agent/kit.cmds\""
check "stack .gitignore lines live inside the kit block" "sed -n '/^# >>> agent-kit/,/^# <<< agent-kit/p' \"\$A/.gitignore\" | grep -qx 'dbt_packages/' && [ \"\$(grep -c '^# >>> agent-kit' \"\$A/.gitignore\")\" = 1 ]"
check "a repo with commits is adopted as existing"   "grep -q 'mode:       existing repo' \"\$A.log\""
check "mypy / pip-audit not used → gates empty, no mypy.ini" "[ -z \"\$(yv \"\$A\" cmd_typecheck)\" ] && [ -z \"\$(yv \"\$A\" cmd_audit)\" ] && [ ! -e \"\$A/ingestion/mypy.ini\" ] && grep -q 'does not use: mypy pip-audit' \"\$A.log\""
check "sqlfluff not used → no lint gate, no .sqlfluff" "! grep -q sqlfluff \"\$A/.agent/project.yaml\" && [ ! -e \"\$A/transform/.sqlfluff\" ]"
check "tools the repo uses keep their gates"        "grep -q '^cmd_lint:.*uv run ruff check' \"\$A/.agent/project.yaml\""
check "dev extra installed: uv sync --extra dev"     "grep -q '^cmd_install: (cd ingestion && uv sync --extra dev)' \"\$A/.agent/project.yaml\""
check "pytest gets the CI's --ignore flags"         "grep -q '^cmd_test:.*pytest -q --ignore=tests/live' \"\$A/.agent/project.yaml\""
check "dbt runs from the uv project that has dbt-core" "grep -q 'cd transform && uv run --project ../ingestion dbt deps' \"\$A/.agent/project.yaml\""
check "no ci target → no --target ci gates, said so" "! grep -q -- '--target ci' \"\$A/.agent/project.yaml\" && grep -q \"has no 'ci' target\" \"\$A.log\""
check "no evaluator package → cmd_arch empty"        "[ -z \"\$(yv \"\$A\" cmd_arch)\" ] && grep -q 'dbt_project_evaluator is not in packages.yml' \"\$A.log\""
check "env template elsewhere → no root .env.example" "[ ! -e \"\$A/.env.example\" ]"
check ".gitignore: covered patterns not repeated"     "! grep -qx '.venv/' \"\$A/.gitignore\" && ! grep -qx '__pycache__/' \"\$A/.gitignore\" && [ \"\$(grep -cx '.env' \"\$A/.gitignore\")\" = 1 ] && grep -qx '.agent/local/' \"\$A/.gitignore\""
check "the whole ignored docs/ is reported"          "grep 'ignores kit files' \"\$A.log\" | grep -q ' docs/'"
check "pre-commit howto installs commit-msg too"     "grep -q 'default_install_hook_types: \[pre-commit, commit-msg\]' \"\$A.log\" && grep -q 'stages: \[commit-msg\]' \"\$A.log\""
out="$(cd "$A" && .agent/scripts/kit-doctor 2>&1 || true)"
check "doctor points at the hook manager"           "printf '%s\n' \"\$out\" | grep -q 'hook manager does not call the kit'"
check "next steps: own branch, MR into main, no develop" "grep -q 'git switch -c chore/agent-kit-setup' \"\$A.log\" && grep -q 'MR into main' \"\$A.log\" && grep -q 'protect main (' \"\$A.log\""
mkdir -p "$A/ingestion/.venv/bin" && printf '#!/bin/sh\n' > "$A/ingestion/.venv/bin/ruff" && chmod +x "$A/ingestion/.venv/bin/ruff"
sed -i.bak 's#^cmd_typecheck:.*#cmd_typecheck: (cd ingestion \&\& uv run mypy .)#' "$A/.agent/project.yaml" && rm -f "$A/.agent/project.yaml.bak"
out="$(cd "$A" && PATH="$UB:$PATH" .agent/scripts/kit-doctor 2>&1 || true)"
check "doctor: uv run <tool> missing from .venv is flagged" "printf '%s\n' \"\$out\" | grep -q \"'mypy' is not in the uv environment of ingestion\" && ! printf '%s\n' \"\$out\" | grep -q \"'ruff' is not in\""
rm -rf "$A/ingestion/.venv"
(cd "$A" && git add -A && git reset -q -- '*.kit-new' && git -c core.hooksPath=/dev/null commit -qm "chore: add agent-kit" --no-verify && rm -f ./*.kit-new docs/*.kit-new)
"$KIT" upgrade "$A" --allow-dirty >"$A.up1.log" 2>&1 || true; "$KIT" upgrade "$A" --allow-dirty >"$A.up2.log" 2>&1 || true
check "kit upgrade (twice) does not bring skipped configs back" "[ ! -e \"\$A/ingestion/mypy.ini\" ] && [ ! -e \"\$A/transform/.sqlfluff\" ]"

# --- .claude/settings.json: the first backup is the user's original and survives later merges
A="$WORK/ex-settings"; ad "$A" 'mkdir -p .claude && printf "{\"permissions\":{\"allow\":[\"Bash(make ORIGINAL)\"]}}\n" > .claude/settings.json && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
jq '.permissions.allow += ["Bash(make mine)"]' "$A/.claude/settings.json" > "$A/s.tmp" && mv "$A/s.tmp" "$A/.claude/settings.json"
"$KIT" upgrade "$A" --allow-dirty >/dev/null 2>&1 || true
check "settings.json.bak-kit still holds the original" "jq -e '.permissions.allow == [\"Bash(make ORIGINAL)\"]' \"\$A/.claude/settings.json.bak-kit\" >/dev/null && grep -q 'make mine' \"\$A/.claude/settings.json\""
"$KIT" upgrade "$A" --allow-dirty >"$A.up2.log" 2>&1 || true
check "settings already merged: next upgrade writes and says nothing" "! grep -q 'merged hooks/permissions' \"\$A.up2.log\""
# a file of the user that got a .kit-new at init: once merged (.kit-new deleted), the same kit does not offer it again
A="$WORK/ex-kitnew"; ad "$A" 'printf "# my own rules\n" > AGENTS.md && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
check "init: own AGENTS.md kept, kit version in .kit-new" "[ -f \"\$A/AGENTS.md.kit-new\" ] && grep -q 'my own rules' \"\$A/AGENTS.md\""
rm -f "$A/AGENTS.md.kit-new"; commit_all "$A"; "$KIT" upgrade "$A" >"$A.up.log" 2>&1 || true
check "merged .kit-new is not offered again by the same kit" "[ ! -e \"\$A/AGENTS.md.kit-new\" ] && grep -q ' AGENTS.md\$' \"\$A/.agent/kit.manifest\""
sed -i.bak 's/^[0-9a-f]*  AGENTS.md$/0000000000000000000000000000000000000000000000000000000000000000  AGENTS.md/' "$A/.agent/kit.manifest" && rm -f "$A/.agent/kit.manifest.bak"
commit_all "$A"; "$KIT" upgrade "$A" >"$A.up2.log" 2>&1 || true
check "…but is offered again when the kit's version changes" "[ -f \"\$A/AGENTS.md.kit-new\" ] && grep -q 'my own rules' \"\$A/AGENTS.md\""

# --- kit-migrate: kit-adopt-scan inventories old agent rules, links into them, secrets in docs, hidden files, own CI checks
printf '\n== kit-adopt-scan: inventory for kit-migrate (read-only, values never printed)\n'
A="$WORK/ex-migrate"
ad "$A" 'mkdir -p agent docs/nghiep-vu docs/tham-chieu tools/checks \
  && printf "# Rules\nSee agent/rules-security.md and agent/project.md\n" > AGENTS.md && printf "# Security\nnever log tokens\n" > agent/rules-security.md \
  && printf "# Project\n" > agent/project.md && printf "Read agent/rules-security.md first\n" > docs/nghiep-vu/flow.md \
  && printf "{\"client_secret\": \"Zq8vK2mN4pR7sT1w\"}\n" > docs/tham-chieu/api.postman_collection.json \
  && printf "db: postgres://etl:S3cretPw@db:5432/x\n" > docs/nghiep-vu/conn.md \
  && printf "volumes:\n  - ./config/.htpasswd:/etc/nginx/.htpasswd:ro\n" > docs/nghiep-vu/gateway.md \
  && printf "{\n  \"applicant_name\": \"Tran Thi Real\",\n  \"applicant_name\": \"Nguyen Van A (an danh) anonymous\",\n  \"automobile\": \"Toyota Camry\",\n  \"phone\": 0912345678\n}\n" > docs/nghiep-vu/api-sample.md \
  && printf "print(1)\n" > tools/checks/check_registry.py \
  && printf "stages: [test]\nchecks:\n  stage: test\n  script:\n    - python3 tools/checks/check_registry.py --token glpat-SeCrEt0123456789\n" > .gitlab-ci.yml \
  && printf "AGENTS.md\nagent/\ndocs/\n" > .gitignore && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json \
  && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
before="$(git -C "$A" status --porcelain | sort)"
scan="$(cd "$A" && .agent/scripts/kit-adopt-scan 2>/dev/null || true)"
sec() { printf '%s\n' "$scan" | awk -v h="## $1." 'index($0, h) == 1 {f=1; next} /^## / {f=0} f'; }
check "§1 own AGENTS.md and agent/ found"             "sec 1 | grep -q '\`AGENTS.md\` .*your own' && sec 1 | grep -q '\`agent/\`.*2 files' && sec 1 | grep -q 'agent/rules-security.md'"
check "§2 every link into agent/ listed"             "sec 2 | grep -q 'AGENTS.md:2 → agent/rules-security.md' && sec 2 | grep -q 'docs/nghiep-vu/flow.md:1 → agent/rules-security.md'"
check "§3 own docs folders kept, not kit slots"      "sec 3 | grep -q 'docs/nghiep-vu/.*yours'"
check "§4 Postman export + secret-like values found" "sec 4 | grep -q 'api.postman_collection.json — file type' && sec 4 | grep -q 'conn.md:1 — password in URL'"
check "§4 a .htpasswd mount path is not a password"  "! sec 4 | grep -q 'gateway.md'"
check "§4 personal data in API samples is found"    "sec 4 | grep -q 'api-sample.md:2 — personal data (applicant_name)' && ! sec 4 | grep -q 'api-sample.md:3'"
check "§4 unquoted phone found, 'automobile' is not a phone" "sec 4 | grep -q 'api-sample.md:5 — personal data (phone)' && ! sec 4 | grep -q 'api-sample.md:4'"
check "§4 a risky file already out of Git is marked ok, not a to-do" "sec 4 | grep -q '^- docs/tham-chieu/api.postman_collection.json — file type, already kept out of Git (ok)'"
check "§4 never prints the values"                   "! printf '%s\n' \"\$scan\" | grep -q 'S3cretPw' && ! printf '%s\n' \"\$scan\" | grep -q 'Zq8vK2mN4pR7sT1w' && ! printf '%s\n' \"\$scan\" | grep -q 'Tran Thi Real'"
check "§5 the .gitignore lines that hide them"       "sec 5 | grep -q '.gitignore:1 .AGENTS.md.' && sec 5 | grep -q '.gitignore:3 .docs/.'"
check "§6 .kit-new left to merge"                    "sec 6 | grep -q 'AGENTS.md.kit-new'"
check "§7 kit pipeline not included yet"             "sec 7 | grep -q 'NOT included'"
check "§8 CI check no cmd_* covers"                  "sec 8 | grep -q 'tools/checks/check_registry.py'"
check "§8 never prints the CI command (tokens)"       "! printf '%s\n' \"\$scan\" | grep -q 'glpat-SeCrEt'"
check "report saved in .agent/local (ignored)"       "[ -f \"\$A/.agent/local/adopt-scan.md\" ] && git -C \"\$A\" check-ignore -q .agent/local/adopt-scan.md"
check "read-only: git status unchanged"              "[ \"\$(git -C \"\$A\" status --porcelain | sort)\" = \"\$before\" ]"
check "kit-migrate skill installed for every harness" "[ -f \"\$A/.agents/skills/kit-migrate/SKILL.md\" ] && [ -L \"\$A/.claude/skills/kit-migrate\" ] && grep -q '\`kit-migrate\`' \"\$A/AGENTS.md.kit-new\""
out="$(cd "$A" && .agent/scripts/kit-doctor 2>&1 || true)"
check "doctor points at kit-migrate"                 "printf '%s\n' \"\$out\" | grep -q 'old agent rules next to the kit.s: agent/ AGENTS.md.kit-new — run the kit-migrate'"
check "init next steps name kit-migrate"             "grep -q 'run kit-migrate, then kit-onboard' \"\$A.log\""
A="$WORK/ex-clean"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
scan="$(cd "$A" && .agent/scripts/kit-adopt-scan 2>/dev/null || true)"
check "clean repo: nothing to migrate"               "sec 1 | grep -q 'None found' && sec 2 | grep -q '^None' && sec 4 | grep -q 'Nothing found'"

A="$WORK/ex-new"; ad "$A" "$EX_SETUP" --stack python:ingestion,dbt:transform --mode new
check "--mode new: full set-up in an existing repo"  "grep -q '^cmd_typecheck:.*mypy' \"\$A/.agent/project.yaml\" && [ -f \"\$A/ingestion/mypy.ini\" ]"

# --- upgrading an install made by an older kit (the real case: a repo adopted before 0.13 got the full set-up)
printf '\n== kit upgrade of an existing repo: untouched cmd_* follow the kit, --mode existing re-adopts an old install\n'
A="$WORK/up-old"; ad "$A" "$EX_SETUP" --stack python:ingestion,dbt:transform --mode new
sed -i.bak '/^mode:/d' "$A/.agent/kit.lock" && rm -f "$A/.agent/kit.lock.bak" "$A/.agent/kit.cmds"          # = installed before 0.13
sed -i.bak -e 's#^cmd_lint:.*#cmd_lint: make lint#' \
  -e 's#^cmd_install:.*#cmd_install: (cd ingestion \&\& uv sync) \&\& (cd transform \&\& dbt deps)#' \
  -e 's#^cmd_test:.*#cmd_test: (cd ingestion \&\& uv run pytest -q) \&\& (cd transform \&\& dbt build --target ci --exclude package:dbt_project_evaluator)#' \
  "$A/.agent/project.yaml" && rm -f "$A/.agent/project.yaml.bak"   # what kit 0.12 generated, plus one user edit (make lint)
(cd "$A" && rm -f ./*.kit-new && git add -A && git -c core.hooksPath=/dev/null commit -qm "chore: add agent-kit" --no-verify)
"$KIT" upgrade "$A" >"$A.up1.log" 2>&1 || true
check "no mode in kit.lock: upgrade as new, say how to re-adopt" "grep -q 'kit upgrade --mode existing' \"\$A.up1.log\" && grep -q '^cmd_typecheck:.*mypy' \"\$A/.agent/project.yaml\""
check "old install: differing cmd_* only suggested"   "grep -q 'would set these commands differently' \"\$A.up1.log\" && grep -q '^cmd_install: (cd ingestion && uv sync) ' \"\$A/.agent/project.yaml\""
check "no baseline guessed for them in kit.cmds"     "! grep -q '^cmd_install:' \"\$A/.agent/kit.cmds\""
(cd "$A" && git add -A && git -c core.hooksPath=/dev/null commit -qm "chore: upgrade kit" --no-verify)
awk '/^# <<< agent-kit/ { print "my-own-dir/" } { print }' "$A/.gitignore" > "$A/gi.tmp" && mv "$A/gi.tmp" "$A/.gitignore"
(cd "$A" && git add -A && git -c core.hooksPath=/dev/null commit -qm "chore: own ignore" --no-verify)
"$KIT" upgrade "$A" --mode existing >"$A.up2.log" 2>&1 || true
check "--mode existing: kit's untouched mypy.ini / .sqlfluff removed" "[ ! -e \"\$A/ingestion/mypy.ini\" ] && [ ! -e \"\$A/transform/.sqlfluff\" ] && grep -q 'removed ingestion/mypy.ini' \"\$A.up2.log\""
check "--mode existing: commands as an existing-repo init" "[ -z \"\$(yv \"\$A\" cmd_typecheck)\" ] && grep -q '^cmd_test: (cd ingestion && uv run pytest -q --ignore=tests/live)\$' \"\$A/.agent/project.yaml\" && grep -q 'uv run --project ../ingestion dbt deps' \"\$A/.agent/project.yaml\""
check "a user-edited cmd_* is never replaced"         "grep -q '^cmd_lint: make lint\$' \"\$A/.agent/project.yaml\""
check "a line the user put in the kit block survives"  "grep -qx 'my-own-dir/' \"\$A/.gitignore\""
check "backup kept, mode stored in kit.lock"          "[ -f \"\$A/.agent/project.yaml.bak-kit\" ] && grep -q '^mode: existing' \"\$A/.agent/kit.lock\""
check ".gitignore kit block trimmed to what is not covered" "! sed -n '/>>> agent-kit/,/<<< agent-kit/p' \"\$A/.gitignore\" | grep -qx '.env' && grep -qx '.agent/local/' \"\$A/.gitignore\""
cp "$A/.agent/project.yaml" "$A.before"; "$KIT" upgrade "$A" --allow-dirty >"$A.up3.log" 2>&1 || true
check "next upgrade changes nothing more"             "cmp -s \"\$A/.agent/project.yaml\" \"\$A.before\" && [ ! -e \"\$A/ingestion/mypy.ini\" ] && ! grep -q 'removed ' \"\$A.up3.log\""
# kit.cmds: a value the user never edited follows the kit; an edited one stays
A="$WORK/up-cmds"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\",\"scripts\":{\"test\":\"x\"}}\n" > package.json' --stack node
check "init remembers generated commands (kit.cmds)" "grep -q '^cmd_test:' \"\$A/.agent/kit.cmds\" && grep -q '^mode: new' \"\$A/.agent/kit.lock\""
for k in cmd_test cmd_lint; do sed -i.bak "s#^$k:.*#$k: old-kit-$k#" "$A/.agent/project.yaml" "$A/.agent/kit.cmds"; done
sed -i.bak 's#^cmd_lint:.*#cmd_lint: my-own-lint#' "$A/.agent/project.yaml"; rm -f "$A"/.agent/*.bak
(cd "$A" && rm -f ./*.kit-new && git add -A && git -c core.hooksPath=/dev/null commit -qm "chore: base" --no-verify)
"$KIT" upgrade "$A" >"$A.up.log" 2>&1 || true
check "untouched cmd_* updated to the new kit's"     "! grep -q 'old-kit-cmd_test' \"\$A/.agent/project.yaml\" && grep -q '^cmd_test: ' \"\$A/.agent/project.yaml\""
check "edited cmd_* kept"                             "grep -q '^cmd_lint: my-own-lint\$' \"\$A/.agent/project.yaml\""

# ---------------------------------------------------------------- kit-dq (module data, playbook kit-da): read-only SQL checks
printf '\n== kit-dq: data checks correct / complete / fresh / clean, read-only, counts only\n'
if command -v sqlite3 >/dev/null 2>&1; then
  A="$WORK/dq"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node --modules data
  check "data module: kit-da skill, kit-dq, templates, cmd_sql key" "[ -x \"\$A/.agent/scripts/kit-dq\" ] && [ -f \"\$A/.agents/skills/kit-da/SKILL.md\" ] && [ -f \"\$A/.agent/templates/dq/fresh.sql\" ] && grep -q '^cmd_sql:' \"\$A/.agent/project.yaml\" && grep -q '^dq_dir: dq' \"\$A/.agent/project.yaml\""
  rc=0; out="$(cd "$A" && .agent/scripts/kit-dq run 2>&1)" || rc=$?
  check "no cmd_sql → clear error"                    "[ $rc -ne 0 ] && printf '%s' \"\$out\" | grep -q 'cmd_sql is empty'"
  sqlite3 "$A/dq.sqlite" "CREATE TABLE hs(ma TEXT, ten TEXT, so INT); INSERT INTO hs VALUES ('A1','NGUYEN SECRET',5),('A1','x',3),('B2','y',-1);"
  sed -i.bak 's#^cmd_sql:.*#cmd_sql: sqlite3 dq.sqlite#' "$A/.agent/project.yaml" && rm -f "$A/.agent/project.yaml.bak"
  (cd "$A" && .agent/scripts/kit-dq new hs clean dup-ma >/dev/null)
  check "kit-dq new: check from the dimension template" "grep -q 'dimension: clean (sạch) · dataset: hs' \"\$A/dq/hs/clean-dup-ma.sql\""
  printf -- '-- severity: error\n-- why: one row per ma\nSELECT ma, COUNT(*) FROM hs GROUP BY ma HAVING COUNT(*) > 1\n' > "$A/dq/hs/clean-dup-ma.sql"
  printf -- '-- severity: warn\n-- why: so is never negative\nSELECT ma FROM hs WHERE so < 0;\n' > "$A/dq/hs/correct-so.sql"
  printf -- '-- why: every row has a name\nSELECT ma FROM hs WHERE ten IS NULL\n' > "$A/dq/hs/complete-ten.sql"
  printf 'DELETE FROM hs\n' > "$A/dq/hs/clean-evil.sql"; printf 'SELECT 1; DROP TABLE hs\n' > "$A/dq/hs/clean-evil2.sql"
  printf 'SELECT 1 AS x \\! touch pwned\n' > "$A/dq/hs/clean-evil3.sql"
  printf -- "-- severity: warn\nSELECT ma FROM hs WHERE ten IN ('INSERT', 'DELETE') AND ma <> '--'\n" > "$A/dq/hs/correct-literals.sql"
  rc=0; out="$(cd "$A" && .agent/scripts/kit-dq run --report 2>&1)" || rc=$?
  check "duplicate key fails, warn only warns, pass is ok" "printf '%s\n' \"\$out\" | grep -q '^FAIL .*clean-dup-ma' && printf '%s\n' \"\$out\" | grep -q '^WARN .*correct-so' && printf '%s\n' \"\$out\" | grep -q '^ok .*complete-ten'"
  check "writes refused, table intact"                "printf '%s\n' \"\$out\" | grep -q '^REFUSED .*clean-evil.sql' && printf '%s\n' \"\$out\" | grep -q '^REFUSED .*clean-evil2.sql' && [ \"\$(sqlite3 \"\$A/dq.sqlite\" 'select count(*) from hs')\" = 3 ]"
  check "exit 1 on an error-severity failure"         "[ $rc -eq 1 ]"
  check "psql meta-command (backslash) refused"        "printf '%s\n' \"\$out\" | grep -q '^REFUSED .*clean-evil3.sql' && [ ! -e \"\$A/pwned\" ]"
  check "write keywords inside string literals are fine" "printf '%s\n' \"\$out\" | grep -q '^ok .*correct-literals.sql'"
  check "report has counts, never row values"         "grep -q 'clean-dup-ma.sql. | 1 |' \"\$A\"/docs/data/quality/*.md && ! grep -rq 'SECRET' \"\$A/docs/data/quality\" && ! printf '%s' \"\$out\" | grep -q SECRET"
  rc=0; out="$(cd "$A" && .agent/scripts/kit-dq run hs/complete-ten.sql 2>&1)" || rc=$?
  check "one check by path (the last file not matching is fine)" "[ $rc -eq 0 ] && printf '%s\n' \"\$out\" | grep -q '1 check(s): 0 failed'"
else printf '  skip kit-dq (sqlite3 not installed)\n'; fi

# ---------------------------------------------------------------- kit-catalog + kit-doc-coverage (module data)
printf '\n== kit-catalog / kit-doc-coverage: which data to use, and how much of it is documented\n'
A="$WORK/catalog"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node --modules data
check "lakehouse decisions + failure modes shipped"   "[ -f \"\$A/.agent/rules/data/lakehouse.md\" ] && grep -q 'lakehouse.md' \"\$A/.agents/skills/kit-data/SKILL.md\""
check "catalog templates + kit-catalog skill installed" "for f in README entities metrics rules; do [ -f \"\$A/docs/data/catalog/\$f.md\" ] || exit 1; done && [ -L \"\$A/.claude/skills/kit-catalog\" ] && grep -q 'docs/data/catalog' \"\$A/.agents/skills/kit-da/SKILL.md\""
mkdir -p "$A/transform/target"; printf 'name: "lake"\nprofile: lake\n' > "$A/transform/dbt_project.yml"
cat > "$A/transform/target/manifest.json" <<'JSON'
{"nodes": {
  "model.lake.mart_a": {"resource_type": "model", "package_name": "lake", "name": "mart_a", "unique_id": "model.lake.mart_a",
    "original_file_path": "models/gold/mart_a.sql", "description": "Schools per day",
    "columns": {"ma_truong": {"description": "School code"}, "so_hs": {"description": "  "}}},
  "model.lake.silver_b": {"resource_type": "model", "package_name": "lake", "name": "silver_b", "unique_id": "model.lake.silver_b",
    "original_file_path": "models/silver/silver_b.sql", "description": "", "columns": {}},
  "model.dbt_utils.x": {"resource_type": "model", "package_name": "dbt_utils", "name": "x", "unique_id": "model.dbt_utils.x",
    "original_file_path": "models/x.sql", "description": "", "columns": {"c": {"description": ""}}},
  "test.lake.t": {"resource_type": "test", "package_name": "lake", "name": "t", "unique_id": "test.lake.t", "original_file_path": "tests/t.sql", "description": ""}},
 "sources": {"source.lake.raw.hs": {"package_name": "lake", "source_name": "raw", "name": "hs", "unique_id": "source.lake.raw.hs",
    "original_file_path": "models/bronze/sources.yml", "description": "Students from the provider", "columns": {}}}}
JSON
out="$(cd "$A" && .agent/scripts/kit-doc-coverage transform --list 2>&1 || true)"
check "per layer: objects and columns documented"     "printf '%s\n' \"\$out\" | grep -Eq '^gold +1 +1 \(100%\) +1/2 +\( 50%\)' && printf '%s\n' \"\$out\" | grep -Eq '^silver +1 +0 \(  0%\)'"
check "other packages and tests are not counted"      "printf '%s\n' \"\$out\" | grep -Eq '^TOTAL +3 +2 '"
check "--list names the gaps (blank description = missing)" "printf '%s\n' \"\$out\" | grep -q 'silver_b — no description' && printf '%s\n' \"\$out\" | grep -q 'mart_a — columns: so_hs'"
printf '{"nodes": {"model.lake.mart_a": {"columns": {"ma_truong": {}, "so_hs": {}, "nam_hoc": {}}}}, "sources": {}}\n' > "$A/transform/target/catalog.json"
out="$(cd "$A" && .agent/scripts/kit-doc-coverage transform --list 2>&1 || true)"
check "catalog.json: warehouse columns missing from .yml count too" "printf '%s\n' \"\$out\" | grep -Eq '^gold .* 1/3 ' && printf '%s\n' \"\$out\" | grep -q 'columns: nam_hoc,so_hs'"
rc=0; (cd "$A" && .agent/scripts/kit-doc-coverage transform --min 80 >/dev/null 2>&1) || rc=$?
check "--min fails below the threshold"               "[ $rc -eq 1 ]"
rc=0; (cd "$A" && .agent/scripts/kit-doc-coverage transform --min 30 >/dev/null 2>&1) || rc=$?
check "--min passes at or above it"                   "[ $rc -eq 0 ]"

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
gh2="$WORK/glhttp"; issue_project "$gh2" gitlab "http://gitlab.example.test/acme/app.git"
rc=0; out="$(cd "$gh2" && GITLAB_TOKEN=tok .agent/scripts/kit-task sync 2>&1)" || rc=$?
check "token never sent over plain http to a remote host" "[ $rc -ne 0 ] && printf '%s\n' \"\$out\" | grep -q 'refusing to send GITLAB_TOKEN over plain http'"
out="$(GLT=wrong gls sync TASK-001 || true)"
check "a rejected token is reported"                "printf '%s\n' \"\$out\" | grep -q 'HTTP 401'"
: > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "issue created in the encoded project path"   "[ \"\$(gl '[.[]|select(.m==\"POST\" and (.p|endswith(\"/issues\")))|.p]|first')\" = '/api/v4/projects/acme%2Fapp/issues' ]"
check "title and labels sent"                       "[ \"\$(gl '[.[]|select(.m==\"POST\" and (.p|endswith(\"/issues\")))|.form]|first|[.title, (.labels|contains(\"status:todo\") and contains(\"priority:P1\"))]|@csv')\" = '\"[TASK-001] Alpha feature\",true' ]"
check "every request carried the token"             "[ \"\$(gl 'all(.[]; .token==\"secret-token\")')\" = true ]"
check "labels are created first"                    "[ \"\$(gl '[.[]|select(.p|endswith(\"/labels\"))]|length')\" -ge 15 ]"
check "the bugfix / ci / perf type labels exist too"  "grep -q 'type:bugfix' \"$WORK/gl.log\" && grep -q 'type:perf' \"$WORK/gl.log\""
check "number saved in .agent/tasks/.issues"        "grep -qx 'TASK-001=41' \"\$g/.agent/tasks/.issues\""
: > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "second sync updates, adding/removing status" "[ \"\$(gl '[.[]|select(.m==\"PUT\")|.form]|first|[(.add_labels|contains(\"status:todo\")), (.remove_labels|contains(\"status:done\")), (.remove_labels|contains(\"status:todo\"))]|@csv')\" = 'true,true,false' ]"
perl -pi -e 's/^status: todo/status: done/' "$g"/.agent/tasks/TASK-001-*.md; : > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "done → the GitLab issue is closed"           "[ \"\$(gl '[.[]|select(.form.state_event==\"close\")]|length')\" = 1 ]"
perl -pi -e 's/^status: done/status: todo/' "$g"/.agent/tasks/TASK-001-*.md; : > "$WORK/gl.log"; gls sync TASK-001 >/dev/null
check "back to todo → it is reopened"               "[ \"\$(gl '[.[]|select(.form.state_event==\"reopen\")]|length')\" = 1 ]"
out="$(gls pull 7)"
check "pull creates a task from the issue"          "ls \"\$g\"/.agent/tasks/TASK-002-*.md >/dev/null 2>&1 && grep -q '^type: bugfix' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q '^priority: P1' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q '^issue: 7' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q 'Users cannot log in' \"\$g\"/.agent/tasks/TASK-002-*.md && grep -q '^Source: gitlab issue #7' \"\$g\"/.agent/tasks/TASK-002-*.md"
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
check "a branch name outside <type>/ fails"         "printf '%s\n' \"\$out\" | grep -q \"type 'wip' is not one of\""
out="$(kci feature/Bad_Name guard || true)"
check "gitflow: description must be lowercase kebab-case" "printf '%s\n' \"\$out\" | grep -q 'lowercase-kebab-case'"
out="$(cd "$r" && KIT_CI_EVENT=pr KIT_CI_BASE=main KIT_CI_HEAD=feature/TASK-009-x .agent/scripts/kit-ci guard 2>&1 || true)"
check "gitflow: a feature cannot merge into main"   "printf '%s\n' \"\$out\" | grep -q 'only release/\* or hotfix/\* merge into main'"
(cd "$r" && git commit -q --amend -m "feat(TASK-009): add a thing" --no-verify)
rc=0; out="$(kci feature/TASK-009-x guard)" || rc=$?
check "good branch + subject pass"                  "[ $rc -eq 0 ]"
printf 'gitflow_enforce: warn\n' > "$r/.agent/project.yaml"
rc=0; out="$(kci wip/foo guard)" || rc=$?
check "gitflow_enforce: warn → CI warns, does not fail" "[ $rc -eq 0 ] && printf '%s\n' \"\$out\" | grep -q \"WARNING: branch 'wip/foo'\""
rm -f "$r/.agent/project.yaml"
rc=0; out="$(kci feat/bronze-all-string guard)" || rc=$?
check "gitflow: feat/ and bugfix/ are accepted"      "[ $rc -eq 0 ] && kci bugfix/TASK-010-null-date guard >/dev/null"
rc=0; out="$(cd "$r" && KIT_CI_EVENT=pr KIT_CI_BASE=main KIT_CI_HEAD=release/v1.2.0 .agent/scripts/kit-ci guard 2>&1)" || rc=$?
check "gitflow: release/* into main passes the name and direction checks" "! printf '%s\n' \"\$out\" | grep -q 'gitflow:' && ! printf '%s\n' \"\$out\" | grep -q \"branch 'release\""
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


# ---------------------------------------------------------------- review findings (fresh-context review of the multi-host branch)
printf '\n== review findings: global excludes, anchored ignores, multi-stack GitLab, build plugins, TypeScript, dbt evaluator, http token\n'
GX="$WORK/gx"; rm -rf "$GX"; mkdir -p "$GX"; printf '.env\n' > "$GX/excludes"; printf '[core]\n\texcludesFile = %s\n' "$GX/excludes" > "$GX/config"
A="$WORK/rv-global"; fresh "$A"; (cd "$A" && git init -q -b main && printf '{"name":"x","version":"1"}\n' > package.json)
GIT_CONFIG_GLOBAL="$GX/config" "$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules none --stack node >"$A.log" 2>&1 || true
check "a global excludesFile does not drop .env from the repo" "sed -n '/^# >>> agent-kit/,/^# <<< agent-kit/p' \"\$A/.gitignore\" | grep -qx '.env'"
A="$WORK/rv-anchored"; ad "$A" 'printf "/.env\n/secrets/\n" > .gitignore && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node
check "root-anchored /.env does not stand in for .env at any depth" "git -C \"\$A\" check-ignore -q svc/.env && git -C \"\$A\" check-ignore -q svc/secrets/x"
A="$WORK/rv-glmulti"; ad "$A" 'mkdir -p api web && printf "[project]\nname=\"a\"\n" > api/pyproject.toml && printf "{\"name\":\"w\",\"version\":\"1\"}\n" > web/package.json' --stack python:api,node:web --provider gitlab
check "GitLab: no node setup in the python image, guard has no stack setup" "! grep -q 'corepack enable' \"\$A/.gitlab-ci.yml\" && awk '/^kit-guard:/,/^kit-quality:/' \"\$A/.gitlab-ci.yml\" | grep -vq 'pip install' && grep -q 'need another image' \"\$A.log\""
A="$WORK/rv-gradle"; ad "$A" 'printf "plugins { id \"java\" }\n" > build.gradle && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack java-gradle
check "existing Gradle repo: no gates for plugins it lacks" "[ -z \"\$(yv \"\$A\" cmd_format_check)\" ] && [ -z \"\$(yv \"\$A\" cmd_lint)\" ] && [ -z \"\$(yv \"\$A\" cmd_audit)\" ] && [ -z \"\$(yv \"\$A\" cmd_arch)\" ] && grep -qE '^cmd_test: (./gradlew|gradle) ' \"\$A/.agent/project.yaml\" && grep -q 'does not use: spotless' \"\$A.log\""
A="$WORK/rv-gradle2"; ad "$A" 'printf "plugins { id \"java\"\n id \"com.diffplug.spotless\" version \"6.25.0\" }\n" > build.gradle && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack java-gradle
check "…and keeps the ones it has (spotless)"       "grep -qE '^cmd_format_check: (./gradlew|gradle) --no-daemon spotlessCheck' \"\$A/.agent/project.yaml\""
A="$WORK/rv-ts"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\",\"devDependencies\":{\"typescript\":\"5.6.0\"}}\n" > package.json && printf "{}\n" > tsconfig.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
check "existing TypeScript repo keeps its typecheck gate" "grep -q '^cmd_typecheck: npx --no-install tsc --noEmit' \"\$A/.agent/project.yaml\""
A="$WORK/rv-dbt"; ad "$A" 'printf "name: t\nprofile: t\n" > dbt_project.yml && printf "t:\n  outputs:\n    ci:\n      type: duckdb\n" > profiles.yml && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack dbt
check "existing dbt repo without packages.yml: no evaluator gate" "[ -z \"\$(yv \"\$A\" cmd_arch)\" ] && grep -q 'dbt_project_evaluator is not in packages.yml' \"\$A.log\""
A="$WORK/rv-hint"; ad "$A" 'printf "stages: [test]\nmine:\n  script: [echo mine]\n" > .gitlab-ci.yml && printf "{\"name\":\"x\",\"version\":\"1\"}\n" > package.json' --stack node --provider gitlab
check "new project: gitflow_enforce: block"          "grep -q '^gitflow_enforce: block' \"\$A/.agent/project.yaml\""
sed -i.bak '/^gitflow_enforce:/d; /^branch_exempt_regex:/d' "$A/.agent/project.yaml" && rm -f "$A/.agent/project.yaml.bak"   # = installed by 0.13
commit_all "$A"; "$KIT" upgrade "$A" >"$A.up.log" 2>&1 || true
check "upgrade repeats the GitLab include hint"     "grep -q 'local: .gitlab-ci.kit.yml' \"\$A.up.log\""
check "upgraded project: gitflow_enforce: warn (CI warns, does not block)" "grep -q '^gitflow_enforce: warn' \"\$A/.agent/project.yaml\""
A="$WORK/rv-husky4"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\",\"husky\":{\"hooks\":{\"pre-commit\":\"echo\"}}}\n" > package.json' --stack node
check "Husky v4 (package.json hooks): how-to, no .husky/ written" "[ ! -e \"\$A/.husky\" ] && grep -q 'kit-hook pre-commit' \"\$A.log\""


# ---------------------------------------------------------------- gitflow rules (lib.sh) under different configurations
printf '\n== gitflow rules: names, merge directions, staging, trunk, tool branches, protection\n'
G="$WORK/gf"; fresh "$G"; (cd "$G" && git init -q && mkdir -p .agent/scripts release/x && cp "$ROOT/core/.agent/scripts/lib.sh" .agent/scripts/)
gf() { (cd "$G" && bash -c 'source .agent/scripts/lib.sh; "$@"' _ "$@"); }   # gf <function> <args…>
printf 'main_branch: main\ndevelop_branch: develop\n' > "$G/.agent/project.yaml"
check "tool branches are exempt (dependabot, renovate, GitHub revert)" "[ -z \"\$(gf branch_name_problem dependabot/npm_and_yarn/lodash-4.17.21)\" ] && [ -z \"\$(gf branch_name_problem revert-123-feature/x)\" ] && [ -z \"\$(gf merge_target_problem revert-12-release/v1 main)\" ]"
check "versions only for release/hotfix; back-merge-v1.2.0 is fine" "[ -n \"\$(gf branch_name_problem feature/1.2)\" ] && [ -z \"\$(gf branch_name_problem chore/back-merge-v1.2.0)\" ] && [ -z \"\$(gf branch_name_problem hotfix/v1.4.1)\" ]"
check "names longer than branch_max_len are refused" "gf branch_name_problem feature/TASK-001-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa | grep -q 'longer than 60'"
check "hotfix → main and main → develop (back-merge) are allowed" "[ -z \"\$(gf merge_target_problem hotfix/v1.4.1 main)\" ] && [ -z \"\$(gf merge_target_problem main develop)\" ]"
check "develop → main is told to go through a release" "gf merge_target_problem develop main | grep -q 'cut a release'"
check "release/* stays protected even with a release/ folder in the repo" "gf is_protected release/v1 && ! gf is_protected staging"
printf 'main_branch: main\ndevelop_branch: develop\nstaging_branch: staging\n' > "$G/.agent/project.yaml"
check "staging: only develop / release / hotfix go there; staging → main ok" "gf merge_target_problem feature/x staging | grep -q 'only develop' && [ -z \"\$(gf merge_target_problem develop staging)\" ] && [ -z \"\$(gf merge_target_problem release/v1.0.0 staging)\" ] && [ -z \"\$(gf merge_target_problem staging main)\" ] && gf is_protected staging"
printf 'main_branch: main\ndevelop_branch: main\n' > "$G/.agent/project.yaml"
check "trunk-based: feature → main is fine"          "[ -z \"\$(gf merge_target_problem feature/TASK-1-x main)\" ]"

# ---------------------------------------------------------------- safe deploys (0.15): data-deploy checklist, runbook prerequisites + stop criteria
printf '\n== safe deploys: data checklist installed and linked, runbook asks for prerequisites and rollback triggers\n'
A="$WORK/dd-data"; fresh "$A"; (cd "$A" && git init -q -b main)
"$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules data,devops --stack python >"$A.log" 2>&1
check "module data installs the data-deploy checklist" "[ -s \"\$A/.agent/checklists/data-deploy.md\" ]"
check "release.md and kit-data point to it"           "grep -q 'checklists/data-deploy.md' \"\$A/.agent/checklists/release.md\" && grep -q 'checklists/data-deploy.md' \"\$A/.agents/skills/kit-data/SKILL.md\""
(cd "$A" && .agent/scripts/kit-new runbook "Deploy gold" >/dev/null)
rb="$A/docs/platform/runbooks/deploy-gold.md"
check "new runbook has prerequisites and stop criteria before the steps" "[ \"\$(grep -E '^## (Prerequisites and access|Stop and roll back when|Diagnose)\$' \"\$rb\" | tr '\n' '|')\" = '## Prerequisites and access|## Stop and roll back when|## Diagnose|' ]"
A="$WORK/dd-nodata"; fresh "$A"; (cd "$A" && git init -q -b main)
"$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules devops --stack python >"$A.log" 2>&1
check "point of no return stays visible once comments are stripped" "(cd \"\$A\" && .agent/scripts/kit-new runbook \"Visible\" >/dev/null) && perl -0pe 's/<!--.*?-->//gs' \"\$A/docs/platform/runbooks/visible.md\" | grep -q 'Point of no return.*who approves'"
B="$WORK/dd-dataonly"; fresh "$B"; (cd "$B" && git init -q -b main)
"$KIT" init "$B" --yes --no-deps --no-setup --no-tools --modules data --stack python >"$B.log" 2>&1
check "data without devops: the checklist gives a way to create the runbook that works" "grep -q 'kit-new doc docs/platform/runbooks/' \"\$B/.agent/checklists/data-deploy.md\" && (cd \"\$B\" && .agent/scripts/kit-new doc docs/platform/runbooks/deploy.md Deploy >/dev/null) && [ -f \"\$B/docs/platform/runbooks/deploy.md\" ]"
check "data checklist: catch-up before freshness, and a rollback section" "grep -q 'catch-up load first' \"\$B/.agent/checklists/data-deploy.md\" && grep -q '^## 6. If a trigger fires' \"\$B/.agent/checklists/data-deploy.md\""
check "without module data there is no data checklist; release.md says it is module data" "[ ! -e \"\$A/.agent/checklists/data-deploy.md\" ] && grep -q 'module data' \"\$A/.agent/checklists/release.md\""

# ---------------------------------------------------------------- inner loop (0.16): per-file check, repeated stop failures, test_fast, --help
printf '\n== inner loop: file check after each edit, same failure 3 turns, test_fast, kit-task new --help\n'
pv() { sed -n "s/^$2:[[:space:]]*//p" "$1/.agent/project.yaml" | head -n1; }   # whole value (yv stops at the first space)
A="$WORK/il-new"; fresh "$A"; (cd "$A" && git init -q -b main)
"$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules none --stack python >"$A.log" 2>&1
check "new python project: per-file check and PostToolUse hook installed" "[ \"\$(pv \"\$A\" check_file_py)\" = 'ruff format --check --force-exclude -q {file} && ruff check --force-exclude -q {file}' ] && [ -x \"\$A/.agent/hooks/post-edit.sh\" ] && jq -e '.hooks.PostToolUse[0].matcher == \"Edit|Write|MultiEdit\"' \"\$A/.claude/settings.json\" >/dev/null"
check "new project: Stop gate runs test_fast; empty cmd_test_fast is skipped" "grep -q '^stop_checks: format_check lint test_fast' \"\$A/.agent/project.yaml\" && printf '%s' \"\$(cd \"\$A\" && .agent/scripts/kit-run test_fast 2>&1)\" | grep -q 'skip.*test_fast'"
A="$WORK/il-uv"; fresh "$A"; (cd "$A" && git init -q -b main && printf '[project]\nname="x"\n' > pyproject.toml && : > uv.lock)
"$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules none --stack python --mode new >"$A.log" 2>&1
check "uv project: every chained python tool runs through uv" "[ \"\$(pv \"\$A\" check_file_py)\" = 'uv run ruff format --check --force-exclude -q {file} && uv run ruff check --force-exclude -q {file}' ] && [ \"\$(pv \"\$A\" cmd_audit)\" = 'uv run pip-audit' ]"

# the hook itself, on a two-component project: the check runs in the file's component with the path relative to it
H="$WORK/il-hook"; fresh "$H"; mkdir -p "$H/.agent/hooks" "$H/api" "$H/.agent/tasks"
cp "$ROOT"/core/.agent/hooks/{_hooklib.sh,post-edit.sh,stop-gate.sh} "$H/.agent/hooks/"
printf 'components: api=python web=node\ncheck_file_py: test -f {file} && grep -q GOOD {file} || { echo "bad file {file}"; exit 1; }\ncheck_file_sh: no-such-tool-xyz {file}\n' > "$H/.agent/project.yaml"
pe() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" | CLAUDE_PROJECT_DIR="$H" "$H/.agent/hooks/post-edit.sh"; }
echo 'x = 1' > "$H/api/bad.py"; echo 'GOOD = 1' > "$H/api/good.py"; echo 'echo' > "$H/api/t.sh"; echo 'x' > "$H/.agent/tasks/n.py"
check "PostToolUse: a failing file is handed back, path relative to its component" "pe \"\$H/api/bad.py\" | jq -e '.decision == \"block\" and (.reason | test(\"api/bad.py fails\") and test(\"bad file bad.py\"))' >/dev/null"
check "PostToolUse: passing file, kit files, missing tool, no key → silent" "[ -z \"\$(pe \"\$H/api/good.py\")\" ] && [ -z \"\$(pe \"\$H/.agent/tasks/n.py\")\" ] && [ -z \"\$(pe \"\$H/api/t.sh\")\" ] && echo x > \"\$H/api/a.md\" && [ -z \"\$(pe \"\$H/api/a.md\")\" ]"
check "PostToolUse: a path with spaces is quoted" "mkdir -p \"\$H/api/sub dir\" && echo GOOD > \"\$H/api/sub dir/o k.py\" && [ -z \"\$(pe \"\$H/api/sub dir/o k.py\")\" ]"

# review findings: a hanging chain is killed as a whole, wrapper "not installed" is not a finding, & in a name, per-component keys
printf 'components: api=python web=node\ncheck_file_timeout: 1\ncheck_file_py: sleep 8 && echo late\ncheck_file_js: echo "npm error npx canceled due to missing packages"; exit 1\ncheck_file_ts: test -f {file} && ! grep -q BAD {file} || { echo "shared rule {file}"; exit 1; }\ncheck_file_ts__web: grep -q WEB {file} || { echo "web rule {file}"; exit 1; }\ncheck_file_ts__api:\ncheck_file_ts__root: echo "root rule {file}"; exit 1\ncheck_file_js__web: off\ncheck_file_mjs: echo "Error [ERR_MODULE_NOT_FOUND]: Cannot find module ./rules"; exit 1\ncheck_file_cjs: echo " ERR_PNPM_RECURSIVE_EXEC_FIRST_FAIL  Command \\"eslint\\" not found"; exit 1\n' > "$H/.agent/project.yaml"
mkdir -p "$H/web"; echo x > "$H/web/a.js"; echo x > "$H/web/b.ts"; echo x > "$H/api/c.ts"; echo x > "$H/api/a&b.ts"
t0=$SECONDS; o="$(pe "$H/api/good.py")"; dt=$((SECONDS - t0))
check "PostToolUse: timeout kills the whole chain (returns in seconds, silent)" "[ -z \"\$o\" ] && [ \$dt -le 4 ]"
echo x > "$H/api/a.js"; echo x > "$H/web/m.mjs"; echo x > "$H/web/c.cjs"; echo x > "$H/root.ts"
check "PostToolUse: a tool missing behind npx / pnpm is not reported as a lint error" "[ -z \"\$(pe \"\$H/api/a.js\")\" ] && [ -z \"\$(pe \"\$H/web/c.cjs\")\" ]"
check "PostToolUse: a real error that mentions a missing module IS reported" "pe \"\$H/web/m.mjs\" | grep -q 'Cannot find module'"
check "PostToolUse: component key 'off' turns it off there; empty component key falls back to the shared one" "[ -z \"\$(pe \"\$H/web/a.js\")\" ] && echo BAD > \"\$H/api/e.ts\" && pe \"\$H/api/e.ts\" | grep -q 'shared rule e.ts'"
check "PostToolUse: files at the repo root use check_file_<ext>__root" "pe \"\$H/root.ts\" | grep -q 'root rule root.ts'"
check "PostToolUse: a component's own key wins (web), the shared key elsewhere (api)" "pe \"\$H/web/b.ts\" | grep -q 'web rule b.ts' && [ -z \"\$(pe \"\$H/api/c.ts\")\" ]"
check "PostToolUse: '&' in a file name stays part of the name" "[ -z \"\$(pe \"\$H/api/a&b.ts\")\" ]"

# the stacks' own check_file commands, with stub tools on PATH
F="$WORK/il-stubs"; fresh "$F"; mkdir -p "$F/bin" "$F/p"
cat > "$F/bin/gofmt" <<'EOS'
#!/bin/sh
for a; do f=$a; done; grep -q SYNTAXERR "$f" && { echo "$f:1:1: expected '}'" >&2; exit 2; }; exit 0
EOS
cat > "$F/bin/rustfmt" <<'EOS'
#!/bin/sh
echo "$@" > "$STUB_LOG"; exit 0
EOS
cat > "$F/bin/ruff" <<'EOS'
#!/bin/sh
echo "$@" >> "$STUB_LOG"; case " $* " in *" --force-exclude "*) exit 0 ;; esac; echo "E999 excluded.py would be checked"; exit 1
EOS
chmod +x "$F/bin/"*
sv() { sed -n "s/^check_file: //p" "$ROOT/stacks/$1/stack.yaml"; }
runc() { (cd "$F/p" && PATH="$F/bin:$PATH" STUB_LOG="$F/log" bash -c "${1//\{file\}/$2}") >/dev/null 2>&1; }
echo 'package main SYNTAXERR' > "$F/p/m.go"
check "go: a file that does not parse fails the check" "! runc \"\$(sv go)\" m.go"
printf '[package]\nname = "x"\nedition = "2024"\n' > "$F/p/Cargo.toml"; echo 'fn main(){}' > "$F/p/l.rs"
check "rust: the edition comes from Cargo.toml" "runc \"\$(sv rust)\" l.rs && grep -q -- '--edition 2024' \"\$F/log\""
echo 'x=1' > "$F/p/excluded.py"; : > "$F/log"
check "python: files the project excludes stay excluded" "runc \"\$(sv python)\" excluded.py"
check "node: unknown file types and warnings handled by flags" "sv node | grep -q -- '--ignore-unknown' && sv node | grep -q -- '--max-warnings=0'"

G="$WORK/il-stop"; fresh "$G"; mkdir -p "$G/.agent/hooks" "$G/.agent/scripts"
cp "$ROOT"/core/.agent/hooks/{_hooklib.sh,stop-gate.sh} "$G/.agent/hooks/"; cp "$ROOT"/core/.agent/scripts/{kit-run,lib.sh} "$G/.agent/scripts/"
(cd "$G" && git init -q -b main && printf 'stop_checks: lint\ncmd_lint: echo "lint error at line 12"; false\n' > .agent/project.yaml && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify && git checkout -q -b feature/TASK-001-x && echo 'x' > app.py)
sg() { printf '{"stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$G" "$G/.agent/hooks/stop-gate.sh"; }
o1="$(sg)"; o2="$(cd "$G" && sed -i.bak 's/line 12/line 40/' .agent/project.yaml && rm -f .agent/project.yaml.bak; sg)"; o3="$(sg)"
check "Stop gate: same failure (line numbers aside) on turn 3 → stop patching" "printf '%s' \"\$o1\" | jq -e '.decision == \"block\"' >/dev/null && ! printf '%s' \"\$o2\" | grep -q 'SAME FAILURE' && printf '%s' \"\$o3\" | grep -q 'SAME FAILURE 3 turns'"
(cd "$G" && printf 'stop_checks: lint\ncmd_lint: echo "another problem"; false\n' > .agent/project.yaml); o4="$(sg)"
check "Stop gate: a new failure starts counting again" "printf '%s' \"\$o4\" | jq -e '.decision == \"block\"' >/dev/null && ! printf '%s' \"\$o4\" | grep -q 'SAME FAILURE'"

(cd "$G" && printf 'stop_checks: lint\ncmd_lint: echo "same again"; false\n' > .agent/project.yaml); sg >/dev/null; sg >/dev/null
(cd "$G" && git add app.py && git -c core.hooksPath=/dev/null commit -qm checkpoint --no-verify && echo y > app2.py); o5="$(sg)"
check "Stop gate: a checkpoint commit does not reset the count (3rd turn still flagged)" "printf '%s' \"\$o5\" | grep -q 'SAME FAILURE 3 turns'"
(cd "$G" && git add -A && git -c core.hooksPath=/dev/null commit -qm done --no-verify); sg >/dev/null; (cd "$G" && echo z > app3.py); o6="$(sg)"
check "Stop gate: nothing left to check clears the count" "! printf '%s' \"\$o6\" | grep -q 'SAME FAILURE'"

# kit init: components of one stack that need different commands get their own keys; an existing repo keeps only tools it uses
A="$WORK/il-two"; fresh "$A"; (cd "$A" && git init -q -b main && mkdir -p api worker && printf '[project]\nname="a"\n' > api/pyproject.toml && : > api/uv.lock && printf 'x\n' > worker/requirements.txt)
"$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules none --stack python:api,python:worker --mode new >"$A.log" 2>&1
check "two python components (uv / pip): one key each, shared key empty" "grep -qx 'check_file_py:' \"\$A/.agent/project.yaml\" && pv \"\$A\" check_file_py__api | grep -q '^uv run ruff' && pv \"\$A\" check_file_py__worker | grep -q '^ruff format'"
A="$WORK/il-biome"; ad "$A" 'printf "{\"name\":\"x\",\"version\":\"1\",\"devDependencies\":{\"prettier\":\"3\",\"@biomejs/biome\":\"1\"}}\n" > package.json && git add -A && git -c core.hooksPath=/dev/null commit -qm base --no-verify' --stack node
check "existing repo with prettier but no eslint: no per-file check that would call eslint" "! grep -E '^check_file_ts:' \"\$A/.agent/project.yaml\" | grep -q eslint"

A="$WORK/il-up"; fresh "$A"; (cd "$A" && git init -q -b main)
"$KIT" init "$A" --yes --no-deps --no-setup --no-tools --modules none --stack python >"$A.log" 2>&1
sed -i.bak '/^check_file_/d; /^# Checked right after/d; /^cmd_test_fast:/d' "$A/.agent/project.yaml" && rm -f "$A/.agent/project.yaml.bak"
jq 'del(.hooks.PostToolUse)' "$A/.claude/settings.json" > "$A/s.tmp" && mv "$A/s.tmp" "$A/.claude/settings.json"; rm -f "$A/.agent/hooks/post-edit.sh"; grep -v ' .agent/hooks/post-edit.sh$' "$A/.agent/kit.manifest" > "$A/m.tmp" && mv "$A/m.tmp" "$A/.agent/kit.manifest"   # = a 0.15 install
commit_all "$A"; "$KIT" upgrade "$A" >"$A.up.log" 2>&1 || true
check "upgrade: check_file_py added EMPTY, suggestion printed" "grep -qx 'check_file_py:' \"\$A/.agent/project.yaml\" && grep -q 'check_file_py: ruff format --check --force-exclude' \"\$A.up.log\""
check "upgrade: PostToolUse hook merged into the project's settings" "jq -e '.hooks.PostToolUse' \"\$A/.claude/settings.json\" >/dev/null && [ -x \"\$A/.agent/hooks/post-edit.sh\" ]"
n0="$(ls "$A/.agent/tasks" | wc -l)"; ho="$(cd "$A" && .agent/scripts/kit-task new --help 2>&1 || true)"; n1="$(ls "$A/.agent/tasks" | wc -l)"
check "kit-task new --help prints usage and creates no task" "[ \"\$n0\" = \"\$n1\" ] && printf '%s' \"\$ho\" | grep -q 'usage: kit-task new'"
check "kit-task new rejects an unknown option" "printf '%s' \"\$(cd \"\$A\" && .agent/scripts/kit-task new --typo x 2>&1 || true)\" | grep -q \"unknown option '--typo'\""
check "a tracker title starting with '-' still makes a task (kit-task pull passes it after --)" "(cd \"\$A\" && .agent/scripts/kit-task new -- '--force flag is ignored' >/dev/null 2>&1) && ls \"\$A/.agent/tasks\" | grep -q 'force-flag-is-ignored'"
check "reviewers use the session's model" "grep -qx 'model: inherit' \"\$A/.claude/agents/code-reviewer.md\""

printf '\n%d failure(s) — workdir %s\n' "$fail" "$WORK"
[ $fail -eq 0 ]
