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

# the component that holds the file: the longest matching path of `components:` (default: the repo root)
comp="."
for c in $(cfg_hook components); do
  p="${c%%=*}"; [ "$p" = "." ] && continue
  case "$rel/" in "$p"/*) if [ "$comp" = "." ] || [ ${#p} -gt ${#comp} ]; then comp="$p"; fi ;; esac
done
inner="$rel"; [ "$comp" = "." ] || inner="${rel#"$comp"/}"
[ -n "$cmd" ] || exit 0
q="$(printf '%q' "$inner")"
shopt -u patsub_replacement 2>/dev/null || true   # bash >= 5.2 would turn the & of a quoted a\&b.py back into an operator
cmd="${cmd//\{file\}/$q}"

# bounded: a hanging tool must not freeze the session. The command runs in its own process group and the whole group is killed on
# timeout — killing only `bash -c` would leave a chained tool (npx …) holding the output pipe open. (coreutils timeout is not everywhere.)
# Positive whole seconds, default 50, at most 80. Claude Code stops a hook after 60 s by default (settings.json gives this one 90 s), so
# the default stays under both and the tools are killed here, not orphaned.
tmo="$(cfg_hook check_file_timeout)"; case "$tmo" in ''|*[!0-9]*|0) tmo=50 ;; esac; [ "$tmo" -le 80 ] || tmo=80
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
# "Not installed" behind a wrapper or a chain exits 1 or 2. Matched on the shell's and the wrappers' own messages near the top (npm warnings
# skipped), so a real error that merely mentions a missing module (an import the agent just broke) is still reported.
printf '%s\n' "$out" | grep -qE '^(bash: )?(line [0-9]+: )?[^ :]+: command not found$' && exit 0
printf '%s\n' "$out" | grep -vE '^npm (warn|WARN)' | head -n 6 | grep -qE 'npx canceled due to missing packages|could not determine executable to run|^error: Failed to spawn|Command "[^"]+" not found|Couldn.t find a script named|vendor/bin/[^ ]+: No such file' && exit 0
# ESLint reports an explicitly passed file the project ignores as a 0:0 warning (and --max-warnings=0 fails on it): no real finding left → skip
ign='File ignored because|no matching configuration was supplied|outside of base path'
if printf '%s' "$out" | grep -qE "$ign" && ! printf '%s\n' "$out" | grep -E '^[[:space:]]*[0-9]+:[0-9]+[[:space:]]+(error|warning)' | grep -qvE "$ign"; then exit 0; fi

reason="agent-kit: $rel fails its file check (check_file_$ext in .agent/project.yaml). Fix it now — do not relax the tool config:
$(printf '%s\n' "$out" | tail -n 30)"
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
else
  R="$reason" perl -MJSON::PP -e 'print JSON::PP->new->encode({decision=>"block", reason=>$ENV{R}})'
fi
exit 0
