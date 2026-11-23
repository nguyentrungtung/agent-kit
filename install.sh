#!/usr/bin/env bash
# Backward-compatible entry point. Prefer:  ./kit init <dir> [options]   (see ./kit --help)
exec "$(cd "$(dirname "$0")" && pwd)/kit" init "$@"
