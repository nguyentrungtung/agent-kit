#!/usr/bin/env bash
# PostToolUse hook (Edit / Write / MultiEdit): check the file the agent just changed, at once, instead of at the end of the turn.
# Command per extension in .agent/project.yaml: check_file_<ext>: <cmd>, {file} = the path relative to the file's component
# (components: path=stack …), run inside that component; check_file_<ext>__<component> (path with / and - as _) wins for that component
# when components of one stack need different commands. Empty key = no check. A failure is handed back to the agent as
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
grep -q "^check_file_${ext}" .agent/project.yaml 2>/dev/null || exit 0

# the component that holds the file: the longest matching path of `components:` (default: the repo root)
comp="."
for c in $(cfg_hook components); do
  p="${c%%=*}"; [ "$p" = "." ] && continue
  case "$rel/" in "$p"/*) if [ "$comp" = "." ] || [ ${#p} -gt ${#comp} ]; then comp="$p"; fi ;; esac
done
inner="$rel"; [ "$comp" = "." ] || inner="${rel#"$comp"/}"
if [ "$comp" != "." ]; then   # a component's own key (even empty = off for it) wins over the shared one
  key="check_file_${ext}__$(printf '%s' "$comp" | tr -c 'A-Za-z0-9' '_')"
  grep -q "^$key:" .agent/project.yaml 2>/dev/null && cmd="$(cfg_hook "$key")"
fi
[ -n "$cmd" ] || exit 0
q="$(printf '%q' "$inner")"
shopt -u patsub_replacement 2>/dev/null || true   # bash >= 5.2 would turn the & of a quoted a\&b.py back into an operator
cmd="${cmd//\{file\}/$q}"

# bounded: a hanging tool must not freeze the session. The command runs in its own process group and the whole group is killed on
# timeout — killing only `bash -c` would leave a chained tool (npx …) holding the output pipe open. (coreutils timeout is not everywhere.)
tmo="$(cfg_hook check_file_timeout)"; tmo="${tmo:-60}"
out="$(cd "$comp" && perl -e '
  my $t = shift; my $pid = fork; defined $pid or exit 1;
  if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127 }
  $SIG{ALRM} = sub { kill "TERM", -$pid; sleep 1; kill "KILL", -$pid; exit 142 };
  alarm $t; waitpid($pid, 0); exit($? & 127 ? 128 + ($? & 127) : $? >> 8)' "$tmo" bash -c "$cmd" 2>&1)"; rc=$?
[ $rc -eq 0 ] && exit 0
[ $rc -eq 127 ] && exit 0                       # tool not installed here: say nothing, CI and the Stop gate still check
[ $rc -eq 142 ] && exit 0                       # timed out: not a finding
# the same "not installed" behind a wrapper exits 1 or 2: npx --no-install, uv run, vendor/bin, missing node_modules
printf '%s' "$out" | grep -qiE 'command not found|npx canceled due to missing packages|could not determine executable to run|failed to spawn|vendor/bin/[^ ]+: no such file|cannot find module|ERR_MODULE_NOT_FOUND' && exit 0

reason="agent-kit: $rel fails its file check (check_file_$ext in .agent/project.yaml). Fix it now — do not relax the tool config:
$(printf '%s\n' "$out" | tail -n 30)"
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
else
  R="$reason" perl -MJSON::PP -e 'print JSON::PP->new->encode({decision=>"block", reason=>$ENV{R}})'
fi
exit 0
