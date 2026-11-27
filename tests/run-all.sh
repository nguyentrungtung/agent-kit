#!/usr/bin/env bash
# Run agent-kit syntax checks and test suites concurrently in isolated temp dirs.
# Usage: tests/run-all.sh [--offline] [--jobs N]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

offline=0; jobs="${KIT_TEST_JOBS:-4}"
while [ $# -gt 0 ]; do
  case "$1" in
    --offline) offline=1; shift ;;
    --jobs) [ $# -ge 2 ] || { echo "--jobs requires a value" >&2; exit 2; }; jobs="$2"; shift 2 ;;
    -h|--help) sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

t0=$(date +%s)
for f in kit tests/*.sh core/.agent/scripts/kit-* core/.agent/scripts/lib*.sh core/.agent/hooks/*.sh core/.agent/githooks/* modules/*/setup.sh modules/*/files/.agent/plugins/*/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f"
done
python3 -m py_compile scripts/vendor-mattpocock.py
printf '== syntax checks ok (%ss)\n' "$(( $(date +%s) - t0 ))"

TD="$(mktemp -d)"
p_reg="" p_smoke="" p_e2e=""
cleanup() { rm -rf "$TD"; }
abort() {
  for p in "$p_reg" "$p_smoke" "$p_e2e"; do
    [ -n "$p" ] && kill "$p" 2>/dev/null || true
  done
  cleanup
  exit 130
}
trap cleanup EXIT
trap abort INT TERM

export KIT_TEST_JOBS="$jobs"
./tests/regressions.sh --jobs "$jobs" "$TD/reg" >"$TD/reg.log" 2>&1 & p_reg=$!
./tests/smoke.sh "$TD/smoke" >"$TD/smoke.log" 2>&1 & p_smoke=$!
if [ $offline -eq 0 ]; then
  ./tests/e2e-workflow.sh "$TD/e2e" >"$TD/e2e.log" 2>&1 & p_e2e=$!
fi

rc=0
wait "$p_reg" || { echo "FAIL: regressions.sh"; rc=1; }
wait "$p_smoke" || { echo "FAIL: smoke.sh"; rc=1; }
if [ -n "$p_e2e" ]; then
  wait "$p_e2e" || { echo "FAIL: e2e-workflow.sh"; rc=1; }
fi

if [ $rc -ne 0 ]; then
  trap - EXIT
  printf '\n== matching FAIL lines ==\n'
  grep -nE '  FAIL |ERROR|^FAIL' "$TD/reg.log" "$TD/smoke.log" "$TD/e2e.log" 2>/dev/null || true
fi
printf '\n== regressions.sh summary ==\n'; tail -n 15 "$TD/reg.log"
printf '\n== smoke.sh summary ==\n'; tail -n 10 "$TD/smoke.log"
if [ -n "$p_e2e" ]; then
  printf '\n== e2e-workflow.sh summary ==\n'; tail -n 15 "$TD/e2e.log"
fi
[ $rc -eq 0 ] || echo "Logs preserved in: $TD"
printf '\nAll suites completed in %ss (rc=%d)\n' "$(( $(date +%s) - t0 ))" "$rc"
exit "$rc"
