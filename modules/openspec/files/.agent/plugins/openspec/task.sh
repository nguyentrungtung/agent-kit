# Sourced by kit-task (lib.sh + gate helpers in scope)
has_openspec() { [ -d "$KIT_ROOT/openspec" ] && [ -x "$KIT_DIR/scripts/kit-openspec" ]; }
change_dir() { printf '%s/openspec/changes/%s' "$KIT_ROOT" "$1"; }
tasks_of_change() {
  local p; for p in $(task_names_all); do [ "$(fmv "$(task_view "$p")" change)" = "$1" ] && echo "$p"; done; return 0
}
case "${1:-}" in
  new_check)
    ch="${4:-}"
    [ -n "$ch" ] && [ ! -d "$(change_dir "$ch")" ] && warn "OpenSpec change '$ch' not found under openspec/changes/ (create it: kit-new change $ch)" || true ;;
  start_stage)
    [ -d "$KIT_ROOT/openspec" ] && git add -A "$KIT_ROOT/openspec" || true ;;
  start_info)
    ch="${4:-}"
    [ -n "$ch" ] && info "OpenSpec change: openspec/changes/$ch/ (proposal, specs, design, tasks) — read it before coding" || true ;;
  assumptions)
    ch="${4:-}"
    [ -n "$ch" ] && [ -d "$(change_dir "$ch")" ] && printf '%s\n' "$(change_dir "$ch")" || true ;;
  source_re)
    printf '%s\n' 'openspec/specs/[a-z0-9]' ;;
  planning_re)
    printf '%s\n' 'openspec/' ;;
  living_docs_re)
    printf '%s\n' 'openspec/specs/|openspec/changes/[^/]+/(specs/|design\.md$)' ;;
  verify)
    ch="${4:-}"
    if [ -n "$ch" ] && has_openspec; then
      if [ -d "$(change_dir "$ch")" ]; then
        if "$KIT_DIR/scripts/kit-openspec" validate "$ch" --strict --no-interactive >/dev/null 2>&1; then
          gate ok "OpenSpec change '$ch' valid (--strict)"
        else
          gate no "OpenSpec change '$ch' invalid — run: .agent/scripts/kit-openspec validate $ch --strict"
          return 1
        fi
      elif ls -d "$KIT_ROOT"/openspec/changes/archive/*-"$ch" >/dev/null 2>&1; then
        gate ok "OpenSpec change '$ch' already archived"
      else
        gate no "OpenSpec change '$ch' not found"
        return 1
      fi
    fi ;;
  archive)
    _os_archive() {
      local id="$1" f="$2" change="$3" p st open="" unchecked=""
      [ -n "$change" ] && has_openspec && [ -d "$(change_dir "$change")" ] || return 0
      for p in $(tasks_of_change "$change"); do
        [ "$(basename "$p")" = "$(basename "$f")" ] && continue
        st="$(task_effective_status "$(task_view "$p")")"
        case "$st" in done|abandoned|review) ;; *) open="$open $(basename "$p" .md | grep -oE '^TASK-[0-9]+')" ;; esac
      done
      if [ -n "$open" ]; then info "OpenSpec change '$change' still has open tasks:$open — it is archived by the last one"; return 0; fi
      unchecked="$(grep -cE '^[[:space:]]*- \[ \]' "$(change_dir "$change")/tasks.md" 2>/dev/null || true)"
      [ "${unchecked:-0}" -eq 0 ] || die "openspec/changes/$change/tasks.md has $unchecked unticked item(s) — finish them or move them to a new task/change first"
      info "archiving OpenSpec change '$change' → openspec/specs (merged with this PR)"
      "$KIT_DIR/scripts/kit-openspec" archive "$change" -y >/dev/null || die "openspec archive failed — run: .agent/scripts/kit-openspec archive $change"
      log_progress "$f" "OpenSpec change $change archived into openspec/specs"
      git add -A "$KIT_ROOT/openspec" "$KIT_TASKS"
      git commit -q -m "docs($id): archive OpenSpec change $change into specs" || true
    }
    _os_archive "$2" "$3" "$4" ;;
esac
return 0
