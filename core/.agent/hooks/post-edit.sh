#!/usr/bin/env bash
# PostToolUse hook (Edit / Write / MultiEdit): check the file the agent just changed, at once, instead of at the end of the turn.
# Command per extension in .agent/project.yaml: check_file_<ext>: <cmd>, {file} = the path relative to the file's component
# (components: path=stack …), run inside that component. When components of one stack need different commands, kit writes
# check_file_<ext>__<component> (path with non-alphanumerics as _, `root` for .): used when it has a value; `off` turns the check off there.
# Empty everywhere = no check. A failure is handed back to the agent as
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

# the component that holds the file: the longest matching path of `components:` (default: the repo root)
comp="."
for c in $(cfg_hook components); do
  p="${c%%=*}"; [ "$p" = "." ] && continue
  case "$rel/" in "$p"/*) if [ "$comp" = "." ] || [ ${#p} -gt ${#comp} ]; then comp="$p"; fi ;; esac
done
inner="$rel"; [ "$comp" = "." ] || inner="${rel#"$comp"/}"
slug="root"; [ "$comp" = "." ] || slug="$(printf '%s' "$comp" | tr -c 'A-Za-z0-9' '_')"
own="$(cfg_hook "check_file_${ext}__$slug")"
[ -n "$own" ] && cmd="$own"                     # an empty component key falls back to the shared one (kit upgrade adds them empty)
[ -n "$cmd" ] && [ "$cmd" != off ] || exit 0
q="$(printf '%q' "$inner")"
shopt -u patsub_replacement 2>/dev/null || true   # bash >= 5.2 would turn the & of a quoted a\&b.py back into an operator
cmd="${cmd//\{file\}/$q}"

# bounded: a hanging tool must not freeze the session. The command runs in its own process group and the whole group is killed on
# timeout — killing only `bash -c` would leave a chained tool (npx …) holding the output pipe open. (coreutils timeout is not everywhere.)
# Positive whole seconds, at most 80: settings.json gives this hook 90 s, so the group is always killed here, never orphaned by Claude Code.
tmo="$(cfg_hook check_file_timeout)"; case "$tmo" in ''|*[!0-9]*|0) tmo=60 ;; esac; [ "$tmo" -le 80 ] || tmo=80
out="$(cd "$comp" && perl -e '
  my $t = shift; my $pid = fork; defined $pid or exit 1;
  if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127 }
  my $stop = sub { kill "TERM", -$pid; select(undef, undef, undef, 0.5); kill "KILL", -$pid };
  $SIG{ALRM} = sub { $stop->(); exit 142 };
  $SIG{TERM} = $SIG{HUP} = $SIG{INT} = sub { $stop->(); exit 143 };   # the hook itself is stopped: take the tools with it
  alarm $t; waitpid($pid, 0); exit($? & 127 ? 128 + ($? & 127) : $? >> 8)' "$tmo" bash -c "$cmd" 2>&1)"; rc=$?
[ $rc -eq 0 ] && exit 0
[ $rc -eq 127 ] && exit 0                       # tool not installed here: say nothing, CI and the Stop gate still check
[ $rc -eq 142 ] && exit 0                       # timed out: not a finding
# "Not installed" behind a wrapper exits 1 or 2 — matched on the wrappers' own messages in the first lines only, so a real error that
# merely mentions a missing module (an import the agent just broke) is still reported.
printf '%s\n' "$out" | head -n 6 | grep -qE 'npx canceled due to missing packages|could not determine executable to run|^error: Failed to spawn|Command "[^"]+" not found|Couldn.t find a script named|vendor/bin/[^ ]+: No such file' && exit 0
# ESLint reports an explicitly passed ignored file as a warning, which --max-warnings=0 turns into a failure: the project chose to ignore it
[ "$(printf '%s\n' "$out" | grep -cE 'warning|problem')" -le 2 ] && printf '%s' "$out" | grep -q 'File ignored because of a matching ignore pattern' && exit 0

reason="agent-kit: $rel fails its file check (check_file_$ext in .agent/project.yaml). Fix it now — do not relax the tool config:
$(printf '%s\n' "$out" | tail -n 30)"
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
else
  R="$reason" perl -MJSON::PP -e 'print JSON::PP->new->encode({decision=>"block", reason=>$ENV{R}})'
fi
exit 0
