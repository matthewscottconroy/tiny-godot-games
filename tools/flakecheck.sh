#!/usr/bin/env bash
#
# Run each suite several times and report any that do not always agree.
#
#   tools/flakecheck.sh              # every demo whose scripts use the global RNG
#   tools/flakecheck.sh --all        # every demo
#   tools/flakecheck.sh coyote-time  # named demos
#   RUNS=12 tools/flakecheck.sh      # how many times each
#
# Godot seeds the global RNG at startup, so a demo that calls randf() behaves
# differently on every run. A suite that asserts on the outcome then passes most
# of the time and fails in CI for no reason anyone can reproduce — which is
# worse than failing always, because the next person reruns it and moves on.
#
# Two of these were found by accident, one full-suite run apart. This looks for
# the rest on purpose.

set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
RUNS="${RUNS:-8}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: Godot not found. Set GODOT=/path/to/godot or add it to PATH." >&2
  exit 127
fi

demos=()
if [ "${1:-}" = "--all" ]; then
  for d in */; do
    [ -f "${d}project.godot" ] && demos+=("${d%/}")
  done
elif [ "$#" -gt 0 ]; then
  demos=("$@")
else
  # Only the demos that can actually differ between runs.
  while IFS= read -r d; do
    demos+=("$d")
  done < <(grep -rl 'randf()\|randi()\|randf_range\|randi_range\|randomize()' \
             --include='*.gd' ./*/scripts 2>/dev/null | cut -d/ -f2 | sort -u)
fi

echo "Checking ${#demos[@]} demo(s), $RUNS runs each…"
echo

flaky=()
skipped=0
for demo in "${demos[@]}"; do
  demo="${demo%/}"
  if [ ! -f "$demo/tests/test.tscn" ]; then
    skipped=$((skipped + 1))
    continue
  fi
  frames="$(test -f "$demo/tests/frames" && tr -cd '0-9' < "$demo/tests/frames")"

  results=()
  for _ in $(seq "$RUNS"); do
    out="$("$GODOT" --headless --path "$demo" res://tests/test.tscn \
             --quit-after "${frames:-5}" 2>&1)"
    results+=("$(printf '%s\n' "$out" | grep -oE '[0-9]+/[0-9]+ passed' | tail -1)")
  done

  unique="$(printf '%s\n' "${results[@]}" | sort -u)"
  count="$(printf '%s\n' "$unique" | wc -l)"
  if [ "$count" -ne 1 ]; then
    echo "FLAKY  $demo"
    printf '%s\n' "$unique" | sed 's/^/         /'
    flaky+=("$demo")
  else
    printf 'same   %-28s %s\n' "$demo" "${results[0]}"
  fi
done

echo
echo "======================================"
if [ "${#flaky[@]}" -eq 0 ]; then
  echo "  no suite disagreed with itself over $RUNS runs"
else
  echo "  ${#flaky[@]} flaky: ${flaky[*]}"
  echo
  echo "  Seed the global RNG in the suite — seed(12345) — so the demo's own"
  echo "  randf() draws the same sequence every run, or widen the assertion so"
  echo "  it does not depend on which way a coin came down."
fi
[ "$skipped" -gt 0 ] && echo "  ($skipped without a suite)"
echo "======================================"

[ "${#flaky[@]}" -eq 0 ]
