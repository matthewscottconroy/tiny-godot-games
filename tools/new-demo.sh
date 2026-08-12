#!/usr/bin/env bash
#
# Scaffold a new demo with the structure the whole collection uses.
#
#   tools/new-demo.sh my-demo "One-line description for the index"
#
# Creates project.godot, icon.svg, a runnable scene, a script, a test suite, and
# a README with all six required sections. The result passes tools/check_docs.py
# and ./run-tests.sh immediately, so you start from green and edit down.
#
# It does NOT add the demo to the root README index — that needs a category
# decision. check_docs.py will remind you.

set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -lt 1 ]; then
  echo "usage: tools/new-demo.sh <demo-name> [\"index description\"]" >&2
  exit 2
fi

name="${1%/}"
desc="${2:-One-line description of what this demo teaches.}"

if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "error: demo name must be lowercase-with-hyphens (got '$name')" >&2
  exit 2
fi
if [ -e "$name" ]; then
  echo "error: '$name' already exists" >&2
  exit 2
fi

# my-demo -> My Demo, and -> MyDemo for the class name.
title="$(echo "$name" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"

mkdir -p "$name"/{scenes,scripts,tests}

cat > "$name/project.godot" <<EOF
; Engine configuration file.
config_version=5

[application]

config/name="$title"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"
run/main_scene="res://scenes/main.tscn"

[display]

window/size/viewport_width=640
window/size/viewport_height=480

[rendering]

renderer/rendering_method="forward_plus"
EOF

cat > "$name/icon.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" fill="#2980b9" rx="16"/>
  <circle cx="64" cy="64" r="34" fill="white"/>
</svg>
EOF

cat > "$name/scripts/main.gd" <<'EOF'
extends Node2D

# TODO: replace this with the demo. Keep it small — the collection's whole point
# is that one file shows one idea, readable top to bottom.

@onready var _label: Label = $HUD/StatusLabel

var _elapsed := 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	_label.text = "Running for %.1fs" % _elapsed
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	draw_circle(Vector2(320, 240), 40.0 + sin(_elapsed * 2.0) * 8.0, Color(0.35, 0.6, 0.9))
EOF

cat > "$name/scenes/main.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="HUD" type="CanvasLayer" parent="."]

[node name="TitleLabel" type="Label" parent="HUD"]
offset_left = 16.0
offset_top = 12.0
offset_right = 624.0
offset_bottom = 36.0
theme_override_font_sizes/font_size = 18
text = "TODO: title"

[node name="StatusLabel" type="Label" parent="HUD"]
offset_left = 16.0
offset_top = 440.0
offset_right = 624.0
offset_bottom = 464.0
theme_override_font_sizes/font_size = 14
EOF

cat > "$name/tests/test.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_logic.gd" id="1"]

[node name="TestRunner" type="Node"]
script = ExtResource("1")
EOF

cat > "$name/tests/test_logic.gd" <<EOF
extends Node

# Drive the demo's real scripts here, not a copy of their logic. A suite that
# reimplements the mechanism stays green while the demo itself is broken — that
# is exactly how 63 demos once passed their tests without running at all.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_placeholder()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func test_placeholder() -> void:
	print("placeholder")
	# TODO: replace with real assertions against scripts/*.gd
	expect(true, "the suite runs")

func _report() -> void:
	var summary := "[$name] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
EOF

cat > "$name/README.md" <<EOF
# $title

$desc

## Purpose

TODO: why this matters in a real game — the problem it solves, and what goes
wrong without it. Two or three sentences, not a restatement of the title.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | TODO |

<!-- Godot's built-in \`ui_*\` actions are bound to the arrow keys only, and
     \`ui_accept\` is Enter/Space. Only claim the letter keys here if a script
     actually binds \`KEY_A\` / \`KEY_D\` / \`KEY_W\` / \`KEY_S\` — tools/check_docs.py
     enforces this. -->

## How It Works

TODO: the mechanism, in the order it happens.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| \`TODO\` | What it is for |

## Files

| File | What it holds |
|------|---------------|
| \`scripts/main.gd\` | TODO |
| \`scenes/main.tscn\` | The runnable scene |
| \`tests/test_logic.gd\` | Headless test suite |

## Use as a building block

**Copy:** TODO.

**Notes**
- TODO: autoloads, input actions, or project settings an adopter needs.
EOF

echo "Created $name/"
echo
echo "Next:"
echo "  1. Build the demo in $name/scripts/main.gd"
echo "  2. Write real assertions in $name/tests/test_logic.gd"
echo "  3. Fill in the TODOs in $name/README.md"
echo "  4. Add a row to the root README index under the right category"
echo "  5. ./run-tests.sh $name && tools/check_docs.py"
