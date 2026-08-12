#!/usr/bin/env bash
#
# Capture one screenshot per demo.
#
#   tools/screenshots.sh                 # every demo
#   tools/screenshots.sh state-machine   # one or more
#   OUT=docs/img tools/screenshots.sh    # where the PNGs go (default: docs/img)
#
# ---------------------------------------------------------------------------
# REQUIRES A DISPLAY. Godot's --headless mode uses a dummy rendering driver:
# there is no framebuffer, so get_viewport().get_texture().get_image() returns
# null and nothing can be captured. This script therefore runs Godot under
# xvfb-run, a virtual X server.
#
#   Debian/Ubuntu:  sudo apt-get install xvfb
#   Fedora:         sudo dnf install xorg-x11-server-Xvfb
#
# If xvfb is missing the script says so and exits rather than producing blank
# images.
# ---------------------------------------------------------------------------
#
# Capture uses Godot's Movie Maker mode (--write-movie) rather than a script
# injected into each demo, so no demo needs to know it is being screenshotted.
# Movie Maker writes a numbered PNG per frame; we keep one from partway in — by
# then a demo has drawn its first real frame, and anything that animates on
# entry has settled.

set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
OUT="${OUT:-docs/img}"
# Which frame to keep. Early enough to be quick, late enough that _ready() work,
# procedural generation, and intro tweens have all happened.
FRAME="${FRAME:-45}"
TOTAL_FRAMES=$((FRAME + 5))

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: Godot not found. Set GODOT=/path/to/godot or add it to PATH." >&2
  exit 127
fi

if ! command -v xvfb-run >/dev/null 2>&1; then
  cat >&2 <<'MSG'
error: xvfb-run not found.

Screenshots need a real framebuffer. Godot's --headless renderer is a dummy
driver that cannot produce an image, so this script runs Godot under a virtual
X server instead.

  Debian/Ubuntu:  sudo apt-get install xvfb
  Fedora:         sudo dnf install xorg-x11-server-Xvfb
MSG
  exit 127
fi

demos=("$@")
if [ "${#demos[@]}" -eq 0 ]; then
  for d in */; do
    [ -f "${d}project.godot" ] && demos+=("${d%/}")
  done
fi

mkdir -p "$OUT"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

captured=0
failed=0
failed_demos=()

for demo in "${demos[@]}"; do
  demo="${demo%/}"
  [ -f "$demo/project.godot" ] || { echo "SKIP  $demo (no project.godot)"; continue; }

  scene="$(sed -n 's/^run\/main_scene="\(.*\)"$/\1/p' "$demo/project.godot")"
  if [ -z "$scene" ]; then
    echo "FAIL  $demo (no run/main_scene)"
    failed=$((failed + 1)); failed_demos+=("$demo"); continue
  fi

  frames="$work/$demo"
  mkdir -p "$frames"

  # Movie Maker forces a fixed frame rate and writes one PNG per frame, so the
  # capture is deterministic regardless of how fast the machine is.
  xvfb-run -a "$GODOT" --path "$demo" "$scene" \
      --write-movie "$frames/frame.png" \
      --fixed-fps 60 --quit-after "$TOTAL_FRAMES" >/dev/null 2>&1

  # Movie Maker numbers frames; take the newest one at or before FRAME.
  shot="$(ls "$frames"/*.png 2>/dev/null | sort | sed -n "${FRAME}p")"
  [ -z "$shot" ] && shot="$(ls "$frames"/*.png 2>/dev/null | sort | tail -1)"

  if [ -z "$shot" ] || [ ! -s "$shot" ]; then
    echo "FAIL  $demo (no frames written)"
    failed=$((failed + 1)); failed_demos+=("$demo"); continue
  fi

  cp "$shot" "$OUT/$demo.png"
  echo "OK    $demo -> $OUT/$demo.png"
  captured=$((captured + 1))
done

echo
echo "======================================"
echo "  $captured captured, $failed failed"
if [ "$failed" -gt 0 ]; then
  printf '  failed: %s\n' "${failed_demos[*]}"
fi
echo "======================================"

[ "$failed" -eq 0 ]
