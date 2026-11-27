# API CI checks (sourced by kit-ci api)
[ -f docs/api/openapi.yaml ] || { info "no docs/api/openapi.yaml — API checks skipped"; return 0; }
"$KIT_DIR/scripts/kit-run" api
if grep -qE '^cmd_apigen:[[:space:]]*[^#[:space:]]' "$KIT_CFG"; then
  before="$(git status --porcelain)"
  "$KIT_DIR/scripts/kit-run" apigen
  [ "$before" = "$(git status --porcelain)" ] || { git status --short; ci_error "generated API client is stale — run .agent/scripts/kit-run apigen and commit"; return 1; }
else
  info "cmd_apigen is not set — frontend types are not checked against docs/api/openapi.yaml (set it when a frontend consumes the API, kit-api §3b)"
fi
if [ "$EVENT" = pr ] && [ -n "$BASE_REF" ]; then
  fetch_base
  base="$(mktemp)"
  if git show "origin/$BASE_REF:docs/api/openapi.yaml" > "$base" 2>/dev/null; then
    if command -v docker >/dev/null 2>&1; then
      docker run --rm -v "$(dirname "$base"):/base" -v "$PWD/docs/api:/head" tufin/oasdiff:v1.11.1 breaking "/base/$(basename "$base")" /head/openapi.yaml --fail-on ERR
    else warn "docker not available — breaking-change check (oasdiff) skipped"; fi
  else info "no base contract yet"; fi
  rm -f "$base"
fi
