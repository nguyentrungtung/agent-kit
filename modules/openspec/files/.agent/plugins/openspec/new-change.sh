# kit-new change <kebab-name> ["<description>"] [--schema data-flow] → openspec/changes/<name>/ (default schema kit-flow)
name=""; desc=""; schema=kit-flow
while [ $# -gt 0 ]; do case "$1" in --schema) schema="$2"; shift 2 ;; *) if [ -z "$name" ]; then name="$1"; else desc="${desc:+$desc }$1"; fi; shift ;; esac; done
[ -n "$name" ] || die 'usage: kit-new change <kebab-name> ["<description>"] [--schema data-flow]'
printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' || die "change name must be kebab-case (e.g. add-order-export)"
[ -d "$KIT_ROOT/openspec" ] && [ -x "$KIT_DIR/scripts/kit-openspec" ] || die "OpenSpec module not installed (kit add openspec)"
[ -d "$KIT_ROOT/openspec/schemas/$schema" ] || die "schema '$schema' not installed (data-flow comes with module data)"
"$KIT_DIR/scripts/kit-openspec" new change "$name" --schema "$schema" ${desc:+--description "$desc"} >/dev/null || die "openspec new change failed"
echo "openspec/changes/$name/"
info "next: write proposal → specs → design → tasks (Claude Code: /openspec-propose $name, or: .agent/scripts/kit-openspec instructions proposal --change $name)"
