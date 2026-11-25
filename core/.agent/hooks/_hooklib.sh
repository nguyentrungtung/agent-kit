#!/usr/bin/env bash
# Helpers for Claude Code hooks (PreToolUse etc.). Reads hook JSON from stdin once.
# Exit 2 + stderr  => tool call blocked, reason shown to the agent.
# JSON "ask"       => user must confirm in the UI.
HOOK_INPUT="$(cat)"
export HOOK_INPUT

# json_get <dotted.path>  — jq if available, else perl JSON::PP (core module on macOS/Linux)
json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r ".$1 // empty" 2>/dev/null
  else
    P="$1" perl -MJSON::PP -e '
      my $d = eval { JSON::PP->new->decode($ENV{HOOK_INPUT}) } or exit 0;
      for my $k (split /\./, $ENV{P}) { $d = (ref $d eq "HASH") ? $d->{$k} : undef; last unless defined $d }
      print $d if defined $d && !ref $d;'
  fi
}

# re <perl-regex> <text> — portable regex test (BSD grep lacks -P)
re() { P="$1" T="$2" perl -e 'exit(($ENV{T} =~ /$ENV{P}/) ? 0 : 1)'; }

deny() {
  printf 'BLOCKED by agent-kit guardrail: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf 'Do this instead: %s\n' "$2" >&2
  exit 2
}

ask() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg r "agent-kit: $reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  else
    R="agent-kit: $reason" perl -MJSON::PP -e 'print JSON::PP->new->encode({hookSpecificOutput=>{hookEventName=>"PreToolUse",permissionDecision=>"ask",permissionDecisionReason=>$ENV{R}}})'
  fi
  exit 0
}

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cfg_hook() { sed -n "s/^$1:[[:space:]]*//p" "$PROJECT_DIR/.agent/project.yaml" 2>/dev/null | head -n1 | sed -E 's/(^|[[:space:]]+)#.*$//; s/[[:space:]]+$//'; }
PROTECTED_RE="$(cfg_hook protected_regex)"
PROTECTED_RE="${PROTECTED_RE:-^(main|master|develop|release/.*|hotfix/.*)$}"
_stg="$(cfg_hook staging_branch)"; [ -z "$_stg" ] || PROTECTED_RE="(${PROTECTED_RE})|^${_stg}\$"   # same list as the git hooks (lib.sh)
