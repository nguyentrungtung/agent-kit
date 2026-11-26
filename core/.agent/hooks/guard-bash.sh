#!/usr/bin/env bash
# PreToolUse(Bash) guardrail. Blocks: bypassing git hooks, pushing/forcing protected branches,
# destroying work outside kit-task, reading/committing secrets, pipe-to-shell, and asks before deploys.
source "$(dirname "$0")/_hooklib.sh"

cmd="$(json_get tool_input.command)"
[ -z "$cmd" ] && exit 0
c="$(printf '%s' "$cmd" | tr '\n' ' ')"
set -f   # no glob expansion when tokenizing the command

# Commands routed through kit scripts are trusted (they implement the safe version of these ops).
if re '^\s*("?\S*/)?\.agent/scripts/kit-[a-z-]+"?(\s|$)' "$c" && ! re '[;&|`]|\$\(' "$c"; then exit 0; fi

# 1) Never bypass hooks / guardrails
re '--no-verify\b' "$c" && deny "--no-verify bypasses quality/secret hooks" "fix the reported problem, then commit normally"
re 'core\.hooksPath' "$c" && deny "changing core.hooksPath disables git hooks"
re '\b(HUSKY|KIT_SKIP[A-Z_]*|KIT_ALLOW[A-Z_]*|KIT_RELEASE_PREP|SKIP)=' "$c" && deny "skipping hooks via env vars is not allowed"
guard='(\.agent/hooks|\.agent/githooks|\.githooks|\.claude/settings[^ ]*\.json)'
if re "$guard" "$c" && { re '\b(rm|mv|cp|chmod|truncate|ln|tee|install)\b|\bsed\s+(-\S+\s+)*-i' "$c" || re ">>?\s*\S*$guard" "$c"; }; then
  deny "guardrail files can only be changed by a human"
fi

# 2) Protected branches: no push, no force, no history rewrite
if re '\bgit\s+push\b' "$c"; then
  re '\s(-f|--force)(\s|$)|\s\+\S+' "$c" && deny "force push is not allowed" "use: .agent/scripts/kit-task rollback (keeps a backup branch)"
  re '\s--delete\b|\s:\S+' "$c" && deny "deleting remote refs needs a human"
  branch="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  for tok in $c; do
    t="${tok#*:}"; t="${t#refs/heads/}"
    if [[ "$t" =~ $PROTECTED_RE ]]; then deny "pushing to protected branch '$t'" "open a PR: .agent/scripts/kit-task finish"; fi
  done
  # bare `git push` / `git push origin` while sitting on a protected branch
  if [[ "$branch" =~ $PROTECTED_RE ]] && re '\bgit\s+push(\s+-\S+)*(\s+[A-Za-z0-9_.-]+)?\s*($|[;&|])' "$c"; then
    deny "current branch '$branch' is protected" "start a task: .agent/scripts/kit-task start TASK-NNN"
  fi
fi
re '\bgit\s+(reset\s+--hard|clean\s+-\S*f|checkout\s+--\s+\.|restore\s+(--\S+\s+)*\.(\s|$)|stash\s+(drop|clear)|tag\s+-d\s+kit/|branch\s+-D|update-ref\s+-d|reflog\s+expire|filter-branch|filter-repo)' "$c" \
  && deny "this git command destroys work without a backup" "use: .agent/scripts/kit-task rollback [--to base|cp-N]  or  kit-task abandon"
if re '\bgit\s+(commit|merge|rebase|cherry-pick|revert)\b' "$c"; then
  branch="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [[ "$branch" =~ $PROTECTED_RE ]] && deny "do not commit/merge directly on protected branch '$branch'" "start a task branch: .agent/scripts/kit-task start TASK-NNN"
fi

# 3) Secrets: never read, print, copy or stage env/key files
envfile='(^|[\s/"'"'"'=])\.env(\.(?!example|sample|template|dist)[A-Za-z0-9_-]+)?(?=$|[\s"'"'"';|&)])'
keyfile='\.(pem|key|p12|pfx|jks|keystore)\b|\bid_(rsa|ed25519|ecdsa|dsa)\b|\.aws/credentials|\.ssh/|\.kube/config|\.npmrc|\.pypirc|\.netrc|\.docker/config\.json'
if re "$envfile" "$c" || re "$keyfile" "$c"; then
  re '\bgit\s+(rm\s+--cached|check-ignore)\b' "$c" || \
  deny "commands touching secret files (.env, keys, credentials) are blocked" "reference variable NAMES from .env.example; ask the human to set values"
fi
re '^\s*(printenv|env|set|export\s+-p|declare\s+-x)\s*($|[|;&>])' "$c" && deny "dumping environment variables can leak secrets"
re '(?i)echo\s+.*\$\{?[A-Z_]*(SECRET|TOKEN|PASSWORD|PASSWD|API_?KEY|PRIVATE)' "$c" && deny "printing secret env vars is not allowed"
re '\bgit\s+add\s+(-\S*f\b|--force)' "$c" && deny "git add --force can stage ignored secret files"

# 4) Dangerous shell
re '\b(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba|z|da)?sh\b' "$c" && deny "piping downloads into a shell is not allowed"
re '\brm\s+(-\S*\s+)*-\S*[rR]\S*\s+(-\S+\s+)*("|'"'"')?(/|~|\$HOME|\.|\.\.|\*|\.git|\.agent)("|'"'"')?(\s|/?$|/\*)' "$c" \
  && deny "recursive delete of a critical path" "delete specific files/dirs by name"
re '\bsudo\b' "$c" && deny "sudo is not allowed for the agent"
re '\bchmod\s+(-R\s+)?777\b' "$c" && deny "chmod 777 is insecure"

# 5) Deploy / publish / infra changes → a human must approve
deploy='\b(terraform\s+(apply|destroy|import|state\s+rm)|kubectl\s+(apply|delete|scale|rollout|patch|edit|create|replace|drain)|helm\s+(install|upgrade|uninstall|rollback)|docker\s+push|npm\s+publish|yarn\s+publish|pnpm\s+publish|mvn\s+\S*\s*deploy|gradlew?\s+\S*publish|cargo\s+publish|twine\s+upload|gh\s+release\s+create|vercel\s+.*--prod|netlify\s+deploy\s+.*--prod|firebase\s+deploy|fly(ctl)?\s+deploy|serverless\s+deploy|aws\s+\S+\s+(delete|terminate|put-secret|update-secret|rm)|gcloud\s+.*\s(delete|deploy)|az\s+.*\s(delete|deploy)|psql\s+.*(prod|production)|DROP\s+(TABLE|DATABASE)|TRUNCATE\s+TABLE)'
# 6) Data: production targets/warehouses need a human
re '(--target[= ]+(prod|production)\b|\b(dbt|sqlmesh)\b.*\bprod(uction)?\b|airflow\s+(dags\s+(trigger|backfill|delete)|tasks\s+clear))' "$c" \
  && ask "data command against production / scheduler state: $cmd"

# 7) Local docker is fine via kit-run up/down; destroying data or images needs a human
re '\bdocker(-compose|\s+compose)?\s+.*\bdown\b.*\s(-v|--volumes)\b|\bdocker\s+(volume\s+(rm|prune)|system\s+prune|image\s+prune|rmi)\b' "$c" \
  && ask "destroys local Docker data/images: $cmd"
extra="$(cfg_hook ask_commands_extra)"
re "(?i)$deploy" "$c" && ask "deploy/publish/infra/destructive-data command: $cmd"
[ -n "$extra" ] && re "$extra" "$c" && ask "project rule (ask_commands_extra): $cmd"

exit 0
