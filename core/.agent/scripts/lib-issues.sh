#!/usr/bin/env bash
# Issue-tracker access for `kit-task sync` / `kit-task pull`: GitHub (gh CLI) or GitLab (REST API v4 — gitlab.com or self-hosted).
# Source it after lib.sh; do not execute. The caller provides cfg, git_provider, remote, warn, die.
#
# GitLab needs no CLI, only curl + jq and a token in the environment (never stored by the kit):
#   GITLAB_TOKEN            personal / project access token with the `api` scope
# The host and project come from the git remote (https://host/group/proj.git, git@host:group/proj.git, ssh://git@host/group/proj.git).
# Self-hosted with a sub-path, a custom port or a non-standard remote? Set in .agent/project.yaml:
#   gitlab_url: https://gitlab.example.com        gitlab_project: group/subgroup/project

# ---- GitLab connection: sets GL_BASE, GL_PROJ (URL-encoded path) and GL_TOKEN once per process
gl_conn() {
  [ -z "${GL_BASE:-}" ] || return 0
  local base proj tok u scheme rest host path
  base="$(cfg gitlab_url)"; proj="$(cfg gitlab_project)"
  if [ -z "$base" ] || [ -z "$proj" ]; then
    u="$(git remote get-url "$(remote)" 2>/dev/null || true)"
    case "$u" in
      http://*|https://*) scheme="${u%%://*}"; rest="${u#*://}"; rest="${rest#*@}"; host="${rest%%/*}"; path="${rest#*/}" ;;
      ssh://*) scheme=https; rest="${u#ssh://}"; rest="${rest#*@}"; host="${rest%%/*}"; host="${host%%:*}"; path="${rest#*/}" ;;
      *@*:*) scheme=https; rest="${u#*@}"; host="${rest%%:*}"; path="${rest#*:}" ;;
      *) die "cannot read a GitLab project from the remote '${u:-<none>}' — set gitlab_url and gitlab_project in .agent/project.yaml" ;;
    esac
    path="${path%.git}"; path="${path%/}"
    [ -n "$base" ] || base="$scheme://$host"
    [ -n "$proj" ] || proj="$path"
  fi
  tok="${GITLAB_TOKEN:-${GITLAB_PRIVATE_TOKEN:-}}"
  [ -n "$tok" ] || die "set GITLAB_TOKEN to an access token with the 'api' scope (the kit never stores it)"
  command -v curl >/dev/null 2>&1 || die "curl is needed for GitLab issue sync"
  command -v jq >/dev/null 2>&1 || die "jq is needed for GitLab issue sync"
  GL_BASE="${base%/}"; GL_PROJ="$(printf '%s' "$proj" | jq -sRr '@uri')"; GL_TOKEN="$tok"
}

# gl_api <METHOD> <path under the project> [curl args…] — prints the JSON body; non-zero (and a warning unless GL_QUIET=1) on HTTP >= 400.
# The token goes through a 0600 header file, not the command line (visible in `ps`).
gl_api() {
  gl_conn
  local m="$1" p="$2" hf out code; shift 2
  hf="$(mktemp)"; out="$(mktemp)"; chmod 600 "$hf"; printf 'PRIVATE-TOKEN: %s\n' "$GL_TOKEN" > "$hf"
  code="$(curl -sS -o "$out" -w '%{http_code}' -X "$m" -H "@$hf" "$@" "$GL_BASE/api/v4/projects/$GL_PROJ$p")" || { rm -f "$hf" "$out"; return 1; }
  rm -f "$hf"
  if [ "${code:-0}" -ge 400 ]; then
    [ "${GL_QUIET:-0}" = 1 ] || warn "GitLab API $m $p → HTTP $code: $(jq -r '.message // .error // .' "$out" 2>/dev/null | head -c 300)"
    rm -f "$out"; return 1
  fi
  cat "$out"; rm -f "$out"
}

# ---- provider-neutral operations (issue numbers: GitHub #n, GitLab iid)
iss_ready() {
  case "$(git_provider)" in
    github)
      command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) not installed"
      gh auth status >/dev/null 2>&1 || die "gh not authenticated — run: gh auth login" ;;
    gitlab) gl_conn ;;
    *) die "git_provider must be github or gitlab (got '$(git_provider)')" ;;
  esac
}

iss_label() { # iss_label <name> <hex colour without #> — create it when missing
  case "$(git_provider)" in
    github) gh label create "$1" --color "$2" --force >/dev/null 2>&1 || true ;;
    gitlab) GL_QUIET=1 gl_api POST /labels --data-urlencode "name=$1" --data-urlencode "color=#$2" >/dev/null 2>&1 || true ;;   # 409 = exists
  esac
}

iss_create() { # <title> <body-file> <label,label,…> → prints the issue URL (its last path segment is the number)
  case "$(git_provider)" in
    github) local args=() l; for l in ${3//,/ }; do args+=(--label "$l"); done
            gh issue create --title "$1" --body-file "$2" "${args[@]}" ;;
    gitlab) gl_api POST /issues --data-urlencode "title=$1" --data-urlencode "description@$2" --data-urlencode "labels=$3" | jq -er .web_url ;;
  esac
}

iss_update() { # <n> <title> <body-file> <labels to add,csv> <labels to remove,csv>
  case "$(git_provider)" in
    github) gh issue edit "$1" --title "$2" --body-file "$3" --add-label "$4" --remove-label "$5" ;;
    gitlab) gl_api PUT "/issues/$1" --data-urlencode "title=$2" --data-urlencode "description@$3" \
              --data-urlencode "add_labels=$4" --data-urlencode "remove_labels=$5" >/dev/null ;;
  esac
}

iss_close() { # <n> <completed|not-planned>
  case "$(git_provider)" in
    github) gh issue close "$1" --reason "$( [ "$2" = completed ] && echo completed || echo 'not planned')" ;;
    gitlab) gl_api PUT "/issues/$1" --data-urlencode "state_event=close" >/dev/null ;;
  esac
}

iss_reopen_if_closed() { # <n>
  case "$(git_provider)" in
    github) [ "$(gh issue view "$1" --json state -q .state 2>/dev/null)" = CLOSED ] && gh issue reopen "$1" ;;
    gitlab) [ "$(gl_api GET "/issues/$1" | jq -r .state)" = closed ] && gl_api PUT "/issues/$1" --data-urlencode "state_event=reopen" >/dev/null ;;
  esac
}

iss_view() { # <n> → JSON {title, body, labels:[names]} (same shape for both providers)
  case "$(git_provider)" in
    github) gh issue view "$1" --json title,body,labels | jq '{title, body, labels: [.labels[].name]}' ;;
    gitlab) gl_api GET "/issues/$1" | jq '{title, body: (.description // ""), labels}' ;;
  esac
}
