#!/usr/bin/env bash
# PreToolUse(Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob) guardrail.
#  - secrets (.env, keys, credentials): never read or written by the agent
#  - guardrail files (hooks, git hooks, Claude settings, .git/): read-only for the agent
#  - CI workflows: editing needs human confirmation
source "$(dirname "$0")/_hooklib.sh"

tool="$(json_get tool_name)"
p="$(json_get tool_input.file_path)"
[ -z "$p" ] && p="$(json_get tool_input.notebook_path)"
[ -z "$p" ] && p="$(json_get tool_input.path)"
[ -z "$p" ] && exit 0
rel="${p#"$PROJECT_DIR"/}"

secret='(^|/)\.env(\.(?!example$|sample$|template$|dist$)[^/]+)?$|\.(pem|key|p12|pfx|jks|keystore)$|(^|/)id_(rsa|ed25519|ecdsa|dsa)$|(^|/)\.aws/credentials$|(^|/)\.ssh/|(^|/)credentials(\.json)?$|service-account[^/]*\.json$|(^|/)secrets?/|\.tfstate(\.backup)?$|(^|/)\.(npmrc|pypirc|netrc)$'
if re "$secret" "$rel"; then
  deny "access to secret file '$rel'" "use .env.example for variable names; values are set by a human"
fi

case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit)
    if re '^(\.agent/hooks/|\.githooks/|\.git/|\.claude/settings(\.local)?\.json$)' "$rel"; then
      deny "guardrail file '$rel' is read-only for the agent" "describe the change; a human applies it"
    fi
    if re '^\.github/workflows/' "$rel"; then
      ask "editing CI workflow '$rel' (can weaken quality gates)"
    fi
    if re '(^|/)(\.php-cs-fixer(\.dist)?\.php|phpstan\.neon(\.dist)?|deptrac\.ya?ml|pint\.json|eslint\.config\.[cm]?[jt]s|\.eslintrc[^/]*|\.prettierrc[^/]*|\.dependency-cruiser\.[cm]?js|ruff\.toml|mypy\.ini|\.importlinter|\.golangci\.ya?ml|rustfmt\.toml|clippy\.toml|deny\.toml|\.editorconfig|Directory\.Build\.props|checkstyle[^/]*\.xml)$' "$rel"; then
      ask "editing quality-tool config '$rel' (must not weaken rules — needs an ADR if relaxing)"
    fi
    if re '^\.agent/rules/' "$rel"; then
      ask "editing project rules '$rel'"
    fi
    if re '^\.agent/project\.yaml$' "$rel"; then
      ask "editing .agent/project.yaml changes lint/test commands and protected branches"
    fi
    ;;
esac
exit 0
