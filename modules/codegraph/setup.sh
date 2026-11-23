#!/usr/bin/env bash
# Runs inside the target project (cwd). Builds the CodeGraph index.
set -eu
if ! command -v codegraph >/dev/null 2>&1; then
  echo "codegraph not installed — install: npm install -g @colbymchenry/codegraph, then run: codegraph init" >&2
  exit 0
fi
[ -d .codegraph ] && { echo "codegraph: .codegraph/ exists — running sync"; codegraph sync . || true; exit 0; }
codegraph init .
