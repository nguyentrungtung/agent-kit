#!/usr/bin/env bash
# Stop hook: before the agent ends its turn on a task branch with uncommitted CODE changes,
# run the fast gates (project.yaml: stop_checks, default "format_check lint"). If they fail,
# block the stop once and hand the errors back so the agent fixes them (or explains why it can't).
# Never loops: when Claude is already continuing because of this hook (stop_hook_active), it lets go.
source "$(dirname "$0")/_hooklib.sh"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

[ "$(json_get stop_hook_active)" = "true" ] && exit 0
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
printf '%s' "$branch" | grep -qE 'TASK-[0-9]+' || exit 0

# only code changes count (docs, task/memory/context notes are free)
changed="$(git status --porcelain 2>/dev/null | cut -c4- | sed 's/.* -> //' \
  | grep -vE '^(docs/|\.agent/(tasks|memory|context|local)/)|\.md$' || true)"
[ -n "$changed" ] || exit 0

steps="$(cfg_hook stop_checks)"; steps="${steps:-format_check lint}"
[ "$steps" = none ] && exit 0

out="$(.agent/scripts/kit-run $steps 2>&1)" && exit 0

reason="agent-kit stop gate: uncommitted code changes fail \`kit-run $steps\`.
Fix the problems below (do not relax tool configs), re-run the gate, then \`kit-task checkpoint\`.
If you cannot fix them now, tell the user exactly what is failing and why.

$(printf '%s\n' "$out" | grep -vE '^\[(run |skip)\]' | tail -n 40)"

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
else
  R="$reason" perl -MJSON::PP -e 'print JSON::PP->new->encode({decision=>"block", reason=>$ENV{R}})'
fi
exit 0
