#!/usr/bin/env bash
# Adds Serena to the project's .mcp.json (Claude Code / other MCP clients read it).
set -eu
command -v jq >/dev/null 2>&1 || { echo "jq required to edit .mcp.json — add serena manually (see agent-kit README)" >&2; exit 0; }
entry='{"command":"uvx","args":["--from","git+https://github.com/oraios/serena","serena","start-mcp-server","--context","ide-assistant","--project","."]}'
[ -f .mcp.json ] || echo '{"mcpServers":{}}' > .mcp.json
jq --argjson e "$entry" '.mcpServers = ((.mcpServers // {}) + {serena: $e})' .mcp.json > .mcp.json.tmp && mv .mcp.json.tmp .mcp.json
echo "serena added to .mcp.json"
command -v uvx >/dev/null 2>&1 || echo "note: uvx not found — install uv (brew install uv) before starting the agent" >&2
