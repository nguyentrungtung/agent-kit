#!/usr/bin/env bash
# Adds Serena to canonical .agent/mcp.json and active harness MCP configs via kit-mcp.
set -eu
[ -x .agent/scripts/kit-mcp ] && .agent/scripts/kit-mcp sync --server serena || true
command -v uvx >/dev/null 2>&1 || echo "note: uvx not found — install uv (brew install uv) before starting the agent" >&2
