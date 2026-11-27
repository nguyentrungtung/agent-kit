case "${1:-}" in
  assumptions) [ -f "$KIT_ROOT/docs/ba/BRIEF.md" ] && printf '%s\n' "$KIT_ROOT/docs/ba/BRIEF.md" || true ;;
  source_re)   printf '%s\n' '(UC|US|BR|FR)-[0-9]+' ;;
esac
return 0
