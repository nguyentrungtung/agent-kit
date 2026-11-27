case "${1:-}" in
  assumptions)    [ -f "$KIT_ROOT/docs/architecture/SOLUTION.md" ] && printf '%s\n' "$KIT_ROOT/docs/architecture/SOLUTION.md" || true ;;
  living_docs_re) printf '%s\n' 'docs/architecture/' ;;
esac
return 0
