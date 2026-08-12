#!/usr/bin/env bash
#
# Run the checks for every demo (or the demos named as arguments).
#
#   ./run-tests.sh                 # check all demos
#   ./run-tests.sh state-machine   # check one or more specific demos
#   GODOT=/path/to/godot ./run-tests.sh
#   ./run-tests.sh --smoke-only    # skip the logic suites
#   ./run-tests.sh --tests-only    # skip the smoke check
#
# Each demo gets two checks:
#
#   1. Smoke — actually boot the demo's main scene headless for a few frames and
#      fail on any script/scene error. The logic suites below construct their own
#      objects, so without this a demo whose scripts do not even parse can still
#      report a green suite. This is the check that covers the real scenes.
#
#   2. Logic — tests/test.tscn runs tests/test_logic.gd, which prints a
#      "[demo] N/M passed" summary line. A demo fails if N != M, if that line is
#      missing, or if Godot exits non-zero.

set -uo pipefail
cd "$(dirname "$0")"

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: Godot not found. Set GODOT=/path/to/godot or add it to PATH." >&2
  exit 127
fi

run_smoke=1
run_logic=1
demos=()
for arg in "$@"; do
  case "$arg" in
    --smoke-only) run_logic=0 ;;
    --tests-only) run_smoke=0 ;;
    -*) echo "error: unknown option $arg" >&2; exit 2 ;;
    *)  demos+=("${arg%/}") ;;
  esac
done

# Default to every demo in the repo.
if [ "${#demos[@]}" -eq 0 ]; then
  for d in */; do
    [ -f "${d}project.godot" ] && demos+=("${d%/}")
  done
fi

# Godot resolves class_name globals and imported assets from .godot/, which a
# fresh clone does not have. Importing first is what CI does; skipping it here
# would make local runs disagree with CI.
echo "Importing $(echo "${#demos[@]}") project(s)…"
for demo in "${demos[@]}"; do
  [ -f "$demo/project.godot" ] || continue
  "$GODOT" --headless --path "$demo" --import --quit >/dev/null 2>&1 || true
done

pass=0
fail=0
failed_demos=()

# Any of these in the output means the demo is broken, even when Godot exits 0.
ERROR_RE='Parse Error|SCRIPT ERROR|SHADER ERROR|Failed to load|Failed to instantiate|^ERROR: '

for demo in "${demos[@]}"; do
  if [ ! -f "$demo/project.godot" ]; then
    echo "SKIP  $demo (no project.godot)"
    continue
  fi

  demo_failed=0

  # --- 1. Smoke: boot the real main scene ---
  if [ "$run_smoke" -eq 1 ]; then
    main_scene="$(sed -n 's/^run\/main_scene="\(.*\)"$/\1/p' "$demo/project.godot")"
    if [ -z "$main_scene" ]; then
      echo "FAIL  $demo (smoke: project.godot has no run/main_scene)"
      demo_failed=1
    else
      smoke_out="$("$GODOT" --headless --path "$demo" "$main_scene" --quit-after 90 2>&1)"
      smoke_status=$?
      smoke_errors="$(printf '%s\n' "$smoke_out" | grep -E "$ERROR_RE")"
      if [ "$smoke_status" -ne 0 ] || [ -n "$smoke_errors" ]; then
        echo "FAIL  $demo (smoke: $main_scene, exit $smoke_status)"
        printf '%s\n' "$smoke_errors" | sed 's/^/      | /'
        demo_failed=1
      fi
    fi
  fi

  # --- 2. Logic: headless test suite ---
  if [ "$run_logic" -eq 1 ] && [ "$demo_failed" -eq 0 ]; then
    if [ ! -f "$demo/tests/test.tscn" ]; then
      echo "FAIL  $demo (no tests/test.tscn)"
      demo_failed=1
    else
      # --quit-after (a few frames) rather than --quit (one frame): a suite that
      # needs a physics step — direct_space_state is only valid inside
      # _physics_process — would otherwise never run. Suites that finish in
      # _ready are unaffected.
      output="$("$GODOT" --headless --path "$demo" res://tests/test.tscn --quit-after 5 2>&1)"
      status=$?

      # The summary line looks like: [demo] 12/12 passed
      summary="$(printf '%s\n' "$output" | grep -oE '[0-9]+/[0-9]+ passed' | tail -1)"
      n="${summary%%/*}"
      m="${summary#*/}"; m="${m%% passed}"

      if [ "$status" -ne 0 ] || [ -z "$summary" ] || [ "$n" != "$m" ]; then
        echo "FAIL  $demo (tests: ${summary:-no summary}, exit $status)"
        printf '%s\n' "$output" | sed 's/^/      | /'
        demo_failed=1
      fi
    fi
  fi

  if [ "$demo_failed" -eq 0 ]; then
    echo "PASS  $demo${summary:+ ($summary)}"
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed_demos+=("$demo")
  fi
  unset summary
done

echo
echo "======================================"
echo "  $pass passed, $fail failed, $((pass + fail)) total"
if [ "$fail" -gt 0 ]; then
  printf '  failed: %s\n' "${failed_demos[*]}"
fi
echo "======================================"

[ "$fail" -eq 0 ]
