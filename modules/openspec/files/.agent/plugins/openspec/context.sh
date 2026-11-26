# Sourced by kit-context: context.sh <hook> [args...]
case "${1:-}" in
  task)
    ch="$(fm_get "$2" change)"
    [ -n "$ch" ] && echo "OpenSpec change: openspec/changes/$ch/ (proposal, specs, design, tasks)"
    return 0 ;;
  refs)
    echo "Current behaviour: openspec/specs/ (source of truth)" ;;
esac
return 0
