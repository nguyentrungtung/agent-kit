#!/usr/bin/env bash
# Runs inside the target project (cwd). Uses an installed codegraph as-is; installs it only when missing (asks first
# unless KIT_YES=1), builds/syncs the index, and syncs MCP config via kit-mcp.
set -eu
yes=""; [ "${KIT_YES:-0}" = 1 ] && yes="--yes"
if [ "${KIT_NO_INSTALL:-0}" = 1 ] && ! command -v codegraph >/dev/null 2>&1; then
  echo "codegraph not installed — not installing (run: kit tools . install). Skipping indexing." >&2; exit 0
fi
.agent/scripts/kit-tools ensure codegraph $yes || { echo "codegraph unavailable — skip indexing (later: npm install -g @colbymchenry/codegraph && codegraph init)" >&2; exit 0; }
if [ -d .codegraph ]; then echo "codegraph: index exists — sync"; codegraph sync . || true
else codegraph init .; fi
[ -x .agent/scripts/kit-mcp ] && .agent/scripts/kit-mcp sync --server codegraph || true
