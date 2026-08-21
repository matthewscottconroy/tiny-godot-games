## Reusable circle-button control.
##
## Input:  configure(specs: Array[Dictionary]) — set number, size, color of circles
## Output: signal circle_clicked(index: int, data: Dictionary) — which was clicked
##         signal hover_changed(index: int) — which is under the cursor, -1 none
extends Control
class_name CircleDisplay

signal circle_clicked(index: int, data: Dictionary)

## The circle under the cursor changed. -1 means the cursor left them all.
##
## Emitted only when it actually changes, not on every mouse move — a caller
## showing a tooltip or playing a sound wants the edge, not the stream.
signal hover_changed(index: int)

var _circles: Array = []
var _hovered: int = -1

const _GAP := 20.0

# Replace the current circle set. Each entry in specs may contain:
#   "color"  : Color   — fill color     (default: WHITE)
#   "radius" : float   — radius px      (default: 30)
#   "label"  : String  — text inside    (default: "")
#   Any extra keys are preserved and forwarded with the click signal.
func configure(specs: Array) -> void:
	_circles = []
	for spec in specs:
		_circles.append(spec.duplicate())
	_place()
	_hovered = -1
	queue_redraw()

# ---- internal layout -------------------------------------------------------

func _place() -> void:
	var total_w := 0.0
	for c in _circles:
		total_w += c.get("radius", 30.0) * 2.0
	if _circles.size() > 1:
		total_w += _GAP * (_circles.size() - 1)

	# store offsets from the control's center so _draw/_hit_test adapt to size
	var x := -total_w * 0.5
	for c in _circles:
		var r: float = c.get("radius", 30.0)
		c["_ox"] = x + r
		c["_oy"] = 0.0
		x += r * 2.0 + _GAP

func _center_of(c: Dictionary) -> Vector2:
	return size * 0.5 + Vector2(c["_ox"], c["_oy"])

# ---- rendering -------------------------------------------------------------

func _draw() -> void:
	if _circles.is_empty():
		return
	var font := ThemeDB.fallback_font
	for i in _circles.size():
		var c: Dictionary = _circles[i]
		var pos  := _center_of(c)
		var r    := c.get("radius", 30.0) as float
		var col  := c.get("color", Color.WHITE) as Color

		if i == _hovered:
			col = col.lightened(0.28)

		draw_circle(pos, r, col)
		draw_arc(pos, r - 1.5, 0.0, TAU, 64, Color(1, 1, 1, 0.35), 2.0)

		var lbl := c.get("label", "") as String
		if lbl != "":
			var fs := clampi(int(r * 0.55), 10, 28)
			draw_string(font,
				Vector2(pos.x - r, pos.y + fs * 0.36),
				lbl,
				HORIZONTAL_ALIGNMENT_CENTER,
				r * 2.0, fs, Color.WHITE)

# ---- input -----------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var hit := _hit_test(event.position)
			if hit >= 0:
				circle_clicked.emit(hit, _circles[hit].duplicate())
	elif event is InputEventMouseMotion:
		var prev := _hovered
		_hovered = _hit_test(event.position)
		if _hovered != prev:
			hover_changed.emit(_hovered)
			queue_redraw()

func _hit_test(local_pos: Vector2) -> int:
	# Reverse order: last-drawn (highest index) gets priority on overlap
	for i in range(_circles.size() - 1, -1, -1):
		var c: Dictionary = _circles[i]
		if local_pos.distance_to(_center_of(c)) <= c.get("radius", 30.0):
			return i
	return -1
