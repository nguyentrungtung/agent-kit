#!/usr/bin/env bash
# PostToolUse hook (Edit / Write / MultiEdit): check the file the agent just changed, at once, instead of at the end of the turn.
# Command per extension in .agent/project.yaml: check_file_<ext>: <cmd>, {file} = the path relative to the file's component
# (components: path=stack …), run inside that component. Empty key = no check. A failure is handed back to the agent as
# feedback (decision "block" on PostToolUse does not undo the edit; it tells the agent to fix it). Never fails the tool call itself.
source "$(dirname "$0")/_hooklib.sh"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

file="$(json_get tool_input.file_path)"
[ -n "$file" ] || exit 0
root="$(pwd -P)"
case "$file" in /*) ;; *) file="$root/$file" ;; esac
[ -f "$file" ] || exit 0
abs="$(cd "$(dirname "$file")" 2>/dev/null && pwd -P)/$(basename "$file")" || exit 0
case "$abs" in "$root"/*) rel="${abs#"$root"/}" ;; *) exit 0 ;; esac   # outside the project: not ours
case "$rel" in .agent/*|.agents/*|.claude/*|.git/*) exit 0 ;; esac

name="${rel##*/}"; case "$name" in *.*) ext="${name##*.}" ;; *) exit 0 ;; esac
case "$ext" in *[!A-Za-z0-9]*) exit 0 ;; esac
cmd="$(cfg_hook "check_file_$ext")"
[ -n "$cmd" ] || exit 0

# the component that holds the file: the longest matching path of `components:` (default: the repo root)
comp="."
for c in $(cfg_hook components); do
  p="${c%%=*}"; [ "$p" = "." ] && continue
  case "$rel/" in "$p"/*) if [ "$comp" = "." ] || [ ${#p} -gt ${#comp} ]; then comp="$p"; fi ;; esac
done
inner="$rel"; [ "$comp" = "." ] || inner="${rel#"$comp"/}"
q="$(printf '%q' "$inner")"
cmd="${cmd//\{file\}/$q}"

# bounded: a hanging tool must not freeze the session (perl alarm; coreutils timeout is not on every machine)
out="$(cd "$comp" && perl -e 'alarm shift; exec @ARGV' 60 bash -c "$cmd" 2>&1)"; rc=$?
[ $rc -eq 0 ] && exit 0
[ $rc -eq 127 ] && exit 0                       # tool not installed here: say nothing, CI and the Stop gate still check
[ $rc -eq 142 ] && exit 0                       # timed out: not a finding

reason="agent-kit: $rel fails its file check (check_file_$ext in .agent/project.yaml). Fix it now — do not relax the tool config:
$(printf '%s\n' "$out" | tail -n 30)"
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
else
  R="$reason" perl -MJSON::PP -e 'print JSON::PP->new->encode({decision=>"block", reason=>$ENV{R}})'
fi
exit 0
