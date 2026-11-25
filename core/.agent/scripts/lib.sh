#!/usr/bin/env bash
# Shared helpers for agent-kit scripts. Source it; do not execute.
set -euo pipefail

KIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
KIT_DIR="$KIT_ROOT/.agent"
KIT_CFG="$KIT_DIR/project.yaml"
KIT_TASKS="$KIT_DIR/tasks"

c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
[ -t 1 ] || { c_red=; c_grn=; c_yel=; c_dim=; c_off=; }

info() { printf '%s[kit]%s %s\n' "$c_grn" "$c_off" "$*"; }
warn() { printf '%s[kit]%s %s\n' "$c_yel" "$c_off" "$*" >&2; }
die()  { printf '%s[kit] ERROR:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }

# cfg <key> [default] — read a flat "key: value" line from project.yaml
cfg() {
  local key="$1" def="${2:-}" val=""
  if [ -f "$KIT_CFG" ]; then
    # value after "key:", minus an inline " # comment", trimmed
    val="$(sed -n "s/^${key}:[[:space:]]*//p" "$KIT_CFG" | head -n1 | sed -E 's/(^|[[:space:]]+)#.*$//; s/[[:space:]]+$//')"
  fi
  printf '%s' "${val:-$def}"
}

main_branch()    { cfg main_branch main; }
develop_branch() { cfg develop_branch develop; }
staging_branch() { cfg staging_branch ""; }   # optional long-lived pre-production branch; empty = release/* is what staging runs
protected_branches() { printf '%s %s %s %s\n' "$(main_branch)" "$(develop_branch)" "$(staging_branch)" "$(cfg protected_extra 'master release/* hotfix/*')"; }

# ---- gitflow (community git-flow + Conventional Branch): one definition for hooks, CI and kit-task
#   main/master  production only — receives release/* and hotfix/* (tagged vX.Y.Z)      → PRODUCTION
#   develop      integration — every feature/bugfix/… merges here, deployed for UAT      → DEV / UAT
#   staging      optional; else release/* is the release candidate                      → STAGING
#   feature/ feat/ bugfix/ fix/ refactor/ chore/ docs/ test/ ci/ perf/ build/ style/ revert/  from develop → develop
#   release/vX.Y.Z  from develop → main (+ back-merge to develop) · hotfix/…  from main → main (+ back-merge to develop) · support/…  old majors
branch_types() { cfg branch_types 'feature feat bugfix fix hotfix release support refactor chore docs test ci perf build style revert'; }
branch_name_problem() { # branch_name_problem <branch> — prints why the name breaks the convention (nothing = fine)
  local b="$1" t rest max
  case " $(main_branch) $(develop_branch) $(staging_branch) main master develop " in *" $b "*) return 0 ;; esac
  t="${b%%/*}"; rest="${b#*/}"
  if [ "$t" = "$b" ] || [ -z "$rest" ]; then echo "no '<type>/' prefix — use <type>/<TASK-NNN>-<short-description>, type one of: $(branch_types)"; return 0; fi
  case " $(branch_types) " in *" $t "*) ;; *) echo "type '$t' is not one of: $(branch_types)"; return 0 ;; esac
  max="$(cfg branch_max_len 60)"
  if [ "${#b}" -gt "$max" ]; then echo "longer than $max characters"; return 0; fi
  # the description: lowercase kebab-case, optionally led by an issue key (TASK-001-…, PROJ-12-…); release/hotfix/support may be a version
  printf '%s' "$rest" | grep -Eq '^([A-Z][A-Z0-9]*-[0-9]+(-[a-z0-9]+)*|v?[0-9]+[.][0-9]+([.][0-9]+)?(-[a-z0-9.]+)?|[a-z0-9]+(-[a-z0-9]+)*)$' \
    || echo "after '$t/' use lowercase kebab-case (a-z 0-9 -), optionally led by an issue key (TASK-001-…) or, for release/hotfix, a version (v1.4.0)"
  return 0
}
merge_target_problem() { # merge_target_problem <source branch> <target branch> — prints why gitflow forbids that merge (nothing = fine)
  local h="$1" b="$2" mb db sb
  mb="$(main_branch)"; db="$(develop_branch)"; sb="$(staging_branch)"
  [ "$mb" != "$db" ] || return 0   # trunk-based: everything goes to main
  if [ "$b" = "$mb" ] || [ "$b" = master ]; then
    case "$h" in release/*|hotfix/*) return 0 ;; esac
    [ -n "$sb" ] && [ "$h" = "$sb" ] && return 0
    echo "only release/* or hotfix/*$( [ -n "$sb" ] && echo " (or $sb)") merge into $b (go-live) — open '$h' into $db"; return 0
  fi
  if [ -n "$sb" ] && [ "$b" = "$sb" ]; then
    case "$h" in "$db"|release/*|hotfix/*) return 0 ;; esac
    echo "only $db, release/* or hotfix/* go to $sb — open '$h' into $db"
  fi
  return 0
}

is_protected() { # is_protected <branch>
  local b="$1" p
  for p in $(protected_branches); do
    # shellcheck disable=SC2053
    [[ "$b" == $p ]] && return 0
  done
  return 1
}

git_provider() { # github | gitlab | none — project.yaml git_provider, else guessed (kit init writes it explicitly; self-hosted: set it)
  local p; p="$(cfg git_provider)"
  if [ -z "$p" ]; then   # same rules as `kit init` (detect_provider): remote host, then the CI files the repo already has
    case "$(git remote get-url "${KIT_REMOTE:-origin}" 2>/dev/null || true)" in
      *github*) p=github ;; *gitlab*) p=gitlab ;;
      *) if [ -f "$KIT_ROOT/.gitlab-ci.yml" ] || [ -d "$KIT_ROOT/.gitlab" ]; then p=gitlab; else p=github; fi ;;
    esac
  fi
  printf '%s' "$p"
}

current_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""; }

# Task id from branch name, e.g. feature/TASK-012-login -> TASK-012
task_from_branch() { current_branch | grep -oE 'TASK-[0-9]+' | head -n1 || true; }

task_file() { # task_file TASK-012 → active file, else archived one (.agent/tasks/archive/YYYY-MM/)
  local f; f="$(ls "$KIT_TASKS"/"$1"-*.md "$KIT_TASKS"/"$1".md 2>/dev/null | head -n1 || true)"
  [ -n "$f" ] || f="$(ls "$KIT_TASKS"/archive/*/"$1"-*.md 2>/dev/null | head -n1 || true)"
  printf '%s' "$f"
}

fm_get() { sed -n "s/^$2:[[:space:]]*//p" "$1" | head -n1; }   # fm_get <file> <key>
fm_set() { # fm_set <file> <key> <value>  (only inside the front matter)
  local f="$1" k="$2" v="$3"
  awk -v k="$k" -v v="$v" 'BEGIN{n=0;done=0}
    /^---[[:space:]]*$/ && n<2 {n++; if(n==2 && !done){print k": "v; done=1}; print; next}
    n==1 && !done && $0 ~ "^"k":" {print k": "v; done=1; next}
    {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

today() { date +%Y-%m-%d; }
now()   { date '+%Y-%m-%d %H:%M'; }

# ---- task views across branches (board, gh sync) ----
fmv() { printf '%s\n' "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n1; }   # fmv "<content>" <key>
task_branch() { # task_branch TASK-012 → local task branch name (not backup/*), else remote one
  local b
  b="$(git for-each-ref --format='%(refname:short)' "refs/heads/*/$1-*" 2>/dev/null | grep -v '^backup/' | head -n1 || true)"
  [ -n "$b" ] || b="$(git for-each-ref --format='%(refname:short)' "refs/remotes/*/*/$1-*" 2>/dev/null | grep -v '/backup/' | head -n1 || true)"
  printf '%s' "$b"
}
task_names_all() { # repo-relative paths of every task: working tree (active + archive), then ones only on branches
  local seen=" " p b n
  for p in $( (ls "$KIT_TASKS" 2>/dev/null | grep -E '^TASK-[0-9]+.*\.md$' | sed 's#^#.agent/tasks/#'
               ls "$KIT_TASKS"/archive/*/ 2>/dev/null >/dev/null && find "$KIT_TASKS/archive" -name 'TASK-*.md' | sed "s#^$KIT_ROOT/##") || true); do
    n="$(basename "$p")"; case "$seen" in *" $n "*) continue ;; esac; seen="$seen$n "; echo "$p"
  done
  for b in $(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null | grep -v '^backup/'); do
    for p in $(git ls-tree --name-only "$b" .agent/tasks/ 2>/dev/null | grep -E '/TASK-[0-9]+[^/]*\.md$' || true); do
      n="$(basename "$p")"; case "$seen" in *" $n "*) continue ;; esac; seen="$seen$n "; echo "$p"
    done
  done
}
task_view() { # task_view <repo-relative task path> → freshest content: its branch tip, else working tree, else develop/main
  local rel="$1" name id br b; name="$(basename "$rel")"; id="$(printf '%s' "$name" | grep -oE '^TASK-[0-9]+')"
  case "$rel" in */archive/*) cat "$KIT_ROOT/$rel" 2>/dev/null; return 0 ;; esac   # archived = final
  br="$(task_branch "$id")"
  if [ -n "$br" ] && git cat-file -e "$br:$rel" 2>/dev/null; then git show "$br:$rel"; return; fi
  [ -f "$KIT_ROOT/$rel" ] && { cat "$KIT_ROOT/$rel"; return; }
  for b in "$(develop_branch)" "$(main_branch)"; do git cat-file -e "$b:$rel" 2>/dev/null && { git show "$b:$rel"; return; }; done
  return 0
}
branch_merged() { # branch_merged <branch> → tip contained in develop or main
  local tip; tip="$(git rev-parse -q --verify "$1" 2>/dev/null || true)"; [ -n "$tip" ] || return 1
  git merge-base --is-ancestor "$tip" "$(develop_branch)" 2>/dev/null || git merge-base --is-ancestor "$tip" "$(main_branch)" 2>/dev/null
}
task_effective_status() { # task_effective_status "<content>" → status, review+merged → done
  local st br; st="$(fmv "$1" status)"; br="$(fmv "$1" branch)"
  if [ "$st" = review ] && [ -n "$br" ] && branch_merged "$br"; then st=done; fi
  printf '%s' "${st:-todo}"
}
# GitHub issue link: front matter `issue:` or the mapping file .agent/tasks/.issues (TASK-NNN=<n>, written by sync-gh;
# kept outside task files so task branches never conflict with it)
ISSUE_MAP="$KIT_TASKS/.issues"
issue_of() { # issue_of <TASK-ID> [<task-content>]
  local n=""; [ -n "${2:-}" ] && n="$(fmv "$2" issue)"
  [ -n "$n" ] || n="$(sed -n "s/^$1=//p" "$ISSUE_MAP" 2>/dev/null | tail -n1)"
  [ -n "$n" ] || n="$(git show "$(develop_branch):.agent/tasks/.issues" 2>/dev/null | sed -n "s/^$1=//p" | tail -n1 || true)"
  printf '%s' "$n"
}
issue_set() { # issue_set <TASK-ID> <n>
  touch "$ISSUE_MAP"; grep -v "^$1=" "$ISSUE_MAP" > "$ISSUE_MAP.tmp" || true
  echo "$1=$2" >> "$ISSUE_MAP.tmp"; sort -o "$ISSUE_MAP" "$ISSUE_MAP.tmp"; rm -f "$ISSUE_MAP.tmp"
}

# ---- OpenSpec links ----
has_openspec() { [ -d "$KIT_ROOT/openspec" ] && [ -x "$KIT_DIR/scripts/kit-openspec" ]; }
change_dir() { printf '%s/openspec/changes/%s' "$KIT_ROOT" "$1"; }
tasks_of_change() { # tasks_of_change <change> → repo-relative task paths linked to it
  local p; for p in $(task_names_all); do [ "$(fmv "$(task_view "$p")" change)" = "$1" ] && echo "$p"; done; return 0
}

# ascii_slug "<text>" [maxlen] → lowercase kebab-case ASCII; strips Vietnamese/Latin diacritics (đ → d)
ascii_slug() {
  perl -CSA -MUnicode::Normalize -e '
    my $s = NFD($ARGV[0]); $s =~ s/\pM//g; $s =~ tr/\x{111}\x{110}/dD/; $s = lc $s;
    $s =~ s/[^a-z0-9]+/-/g; $s =~ s/^-+|-+$//g; print $s' "$1" | cut -c1-"${2:-50}" | sed -E 's/-+$//'
}
