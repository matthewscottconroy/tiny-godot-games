#!/usr/bin/env bash
#
# Export demos to the web, for a playable gallery.
#
#   tools/export_web.sh                  # every demo
#   tools/export_web.sh state-machine    # one or more
#   OUT=build/web tools/export_web.sh    # where the builds go
#
# ---------------------------------------------------------------------------
# This needs Godot's web export templates, which are a separate ~1GB download
# from the editor. `tools/preflight.sh` says whether they are installed before
# you start, rather than the export failing once per demo when they are not.
#
# Every export writes its own 39MB copy of the WebAssembly engine, and the copies
# are byte-identical. Left alone that is 6.2GB for the full set, so the run ends
# by calling tools/share_web_engine.py, which collapses them to one shared copy.
# ---------------------------------------------------------------------------
#
# Godot exports from a named preset in export_presets.cfg, and none of the demos
# have one — adding 165 near-identical files would be noise. This generates the
# preset per demo, exports, then removes it again.
#
# Four demos cannot work unchanged in a browser and are skipped by default:
#
#   multiplayer-rpc   ENet is UDP; browsers cannot open raw UDP sockets.
#                     A web build needs WebSocketMultiplayerPeer or WebRTC.
#   thread-loading    Threads need cross-origin isolation (COOP/COEP headers).
#                     GitHub Pages does not send them, so this needs a host
#                     that does, or a single-threaded build.
#   http-request      Subject to CORS; the public API it calls may refuse a
#                     browser request that works fine from a desktop build.
#   procedural-sfx    Browsers block audio until a user gesture, so the demo
#                     appears silent until something is clicked.
#
# The other audio demos (dynamic-music, music-sequencer) share the gesture
# restriction but still show their visuals, so they are exported.

set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
OUT="${OUT:-build/web}"
SKIP_DEFAULT="multiplayer-rpc thread-loading http-request procedural-sfx"
SKIP="${SKIP:-$SKIP_DEFAULT}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: Godot not found. Set GODOT=/path/to/godot or add it to PATH." >&2
  exit 127
fi

# The export templates are a separate download from the editor.
if ! "$GODOT" --headless --version >/dev/null 2>&1; then
  echo "error: cannot run Godot" >&2
  exit 127
fi

demos=("$@")
if [ "${#demos[@]}" -eq 0 ]; then
  for d in */; do
    [ -f "${d}project.godot" ] && demos+=("${d%/}")
  done
fi

exported=0
skipped=0
failed=0
failed_demos=()

for demo in "${demos[@]}"; do
  demo="${demo%/}"
  [ -f "$demo/project.godot" ] || continue

  if [[ " $SKIP " == *" $demo "* ]]; then
    echo "SKIP  $demo (does not work unchanged in a browser — see the header)"
    skipped=$((skipped + 1))
    continue
  fi

  preset="$demo/export_presets.cfg"
  had_preset=0
  [ -f "$preset" ] && had_preset=1

  if [ "$had_preset" -eq 0 ]; then
    cat > "$preset" <<'PRESET'
[preset.0]

name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
export_path=""

[preset.0.options]

variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
PRESET
  fi

  mkdir -p "$OUT/$demo"
  if "$GODOT" --headless --path "$demo" --export-release "Web" \
      "../$OUT/$demo/index.html" >/dev/null 2>&1; then
    echo "OK    $demo"
    exported=$((exported + 1))
  else
    echo "FAIL  $demo (export failed — are the web export templates installed?)"
    failed=$((failed + 1)); failed_demos+=("$demo")
    rm -rf "${OUT:?}/$demo"
  fi

  [ "$had_preset" -eq 0 ] && rm -f "$preset"
done

# One engine, not one per demo. Skipped when nothing exported, because there is
# then nothing to share and the script would only report an empty directory.
if [ "$exported" -gt 0 ] && [ -x tools/share_web_engine.py ]; then
  echo
  OUT="$OUT" tools/share_web_engine.py
fi

echo
echo "======================================"
echo "  $exported exported, $skipped skipped, $failed failed"
if [ "$failed" -gt 0 ]; then
  printf '  failed: %s\n' "${failed_demos[*]}"
fi
echo "======================================"

[ "$failed" -eq 0 ]
