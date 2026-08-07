#!/usr/bin/env bash
#
# Run the headless test suite for every demo (or the demos named as arguments).
#
#   ./run-tests.sh                 # run all demos
#   ./run-tests.sh state-machine   # run one or more specific demos
#   GODOT=/path/to/godot ./run-tests.sh
#
# Each demo has tests/test.tscn (a Node running tests/test_logic.gd). The suite
# prints a "[demo] N/M passed" summary line; this script treats a demo as failed
# if N != M, if that line is missing, or if Godot exits non-zero.

set -uo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: Godot not found. Set GODOT=/path/to/godot or add it to PATH." >&2
  exit 127
fi

# Determine which demos to run.
if [ "$#" -gt 0 ]; then
  demos=("$@")
else
  demos=()
  for d in */; do
    [ -f "${d}tests/test.tscn" ] && demos+=("${d%/}")
  done
fi

pass=0
fail=0
failed_demos=()

for demo in "${demos[@]}"; do
  demo="${demo%/}"
  if [ ! -f "$demo/tests/test.tscn" ]; then
    echo "SKIP  $demo (no tests/test.tscn)"
    continue
  fi

  output="$("$GODOT" --headless --path "$demo" res://tests/test.tscn --quit 2>&1)"
  status=$?

  # The summary line looks like: [demo] 12/12 passed
  summary="$(printf '%s\n' "$output" | grep -oE '[0-9]+/[0-9]+ passed' | tail -1)"
  n="${summary%%/*}"
  m="${summary#*/}"; m="${m%% passed}"

  if [ "$status" -eq 0 ] && [ -n "$summary" ] && [ "$n" = "$m" ]; then
    echo "PASS  $demo ($summary)"
    pass=$((pass + 1))
  else
    echo "FAIL  $demo (${summary:-no summary}, exit $status)"
    printf '%s\n' "$output" | sed 's/^/      | /'
    fail=$((fail + 1))
    failed_demos+=("$demo")
  fi
done

echo
echo "======================================"
echo "  $pass passed, $fail failed, $((pass + fail)) total"
if [ "$fail" -gt 0 ]; then
  printf '  failed: %s\n' "${failed_demos[*]}"
fi
echo "======================================"

[ "$fail" -eq 0 ]
