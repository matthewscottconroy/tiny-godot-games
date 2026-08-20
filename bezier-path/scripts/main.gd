extends Node2D

# Default control point positions
const DEFAULT_POINTS := [
	Vector2(80, 380),
	Vector2(160, 100),
	Vector2(480, 100),
	Vector2(560, 380),
]

var _points: PackedVector2Array = PackedVector2Array([
	Vector2(80, 380),
	Vector2(160, 100),
	Vector2(480, 100),
	Vector2(560, 380),
])
var _drag: int = -1
var _t: float = 0.0
var _speed: float = 0.4
var _hovered: int = -1

func _bezier(t: float) -> Vector2:
	var p0 := _points[0]
	var p1 := _points[1]
	var p2 := _points[2]
	var p3 := _points[3]
	var u := 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3

func _bezier_tangent(t: float) -> Vector2:
	var p0 := _points[0]
	var p1 := _points[1]
	var p2 := _points[2]
	var p3 := _points[3]
	var u := 1.0 - t
	var tangent := 3.0 * u * u * (p1 - p0) + 6.0 * u * t * (p2 - p1) + 3.0 * t * t * (p3 - p2)
	if tangent.length() > 0.001:
		return tangent.normalized()
	return Vector2(1, 0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag = -1
				for i in range(4):
					if _points[i].distance_to(event.position) < 16.0:
						_drag = i
						break
			else:
				_drag = -1
	elif event is InputEventMouseMotion:
		_hovered = -1
		for i in range(4):
			if _points[i].distance_to(event.position) < 16.0:
				_hovered = i
				break
		if _drag >= 0:
			_points[_drag] = event.position
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_A:
			for i in range(4):
				_points[i] = DEFAULT_POINTS[i]

func _process(delta: float) -> void:
	_t = fmod(_t + _speed * delta, 1.0)
	queue_redraw()

func _draw() -> void:
	# Draw background hint lines (handle lines from endpoints to handles)
	_draw_dashed_line(_points[0], _points[1], Color(0.7, 0.7, 0.7, 0.5), 2.0, 8.0)
	_draw_dashed_line(_points[3], _points[2], Color(0.7, 0.7, 0.7, 0.5), 2.0, 8.0)

	# Draw curve as 80 segments with color gradient
	var steps := 80
	for i in range(steps):
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var p0 := _bezier(t0)
		var p1 := _bezier(t1)
		var col := Color.CORNFLOWER_BLUE.lerp(Color.TOMATO, t0)
		draw_line(p0, p1, col, 3.0)

	# Draw control points
	for i in range(4):
		var pt := _points[i]
		var is_endpoint := (i == 0 or i == 3)
		var is_active := (i == _drag or (i == _hovered and _drag < 0))
		var radius := 10.0 if is_endpoint else 8.0
		if is_endpoint:
			var col := Color.WHITE if is_active else Color(0.9, 0.9, 0.9)
			draw_circle(pt, radius, col)
			draw_arc(pt, radius, 0, TAU, 32, Color.DARK_GRAY, 2.0)
		else:
			var col := Color(1.0, 0.85, 0.3, 1.0) if is_active else Color(1.0, 0.85, 0.3, 0.7)
			draw_arc(pt, radius, 0, TAU, 24, col, 2.5)
			draw_line(pt + Vector2(-4, 0), pt + Vector2(4, 0), col, 1.5)
			draw_line(pt + Vector2(0, -4), pt + Vector2(0, 4), col, 1.5)

	# Draw animated dot at _t
	var dot_pos := _bezier(_t)
	var tangent := _bezier_tangent(_t)
	var perp := Vector2(-tangent.y, tangent.x)

	# Arrow showing tangent direction
	var arrow_len := 28.0
	var arrow_end := dot_pos + tangent * arrow_len
	draw_line(dot_pos, arrow_end, Color.YELLOW, 2.0)
	var arrowhead_size := 7.0
	draw_line(arrow_end, arrow_end - tangent * arrowhead_size + perp * arrowhead_size * 0.5, Color.YELLOW, 2.0)
	draw_line(arrow_end, arrow_end - tangent * arrowhead_size - perp * arrowhead_size * 0.5, Color.YELLOW, 2.0)

	# Dot itself
	draw_circle(dot_pos, 7.0, Color.YELLOW)
	draw_arc(dot_pos, 7.0, 0, TAU, 32, Color.WHITE, 1.5)

	# t-value label near dot
	var label_offset := perp * 20.0 + Vector2(0, -10)
	# LEFT, not CENTER: this label is placed relative to the dot it belongs to,
	# and there is no width to centre it within.
	draw_string(ThemeDB.fallback_font, dot_pos + label_offset, "t=%.2f" % _t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	# Title
	# CENTER needs a width to centre within; with -1 ("no limit") the alignment
	# is ignored and the text is drawn from `pos`, which for a long line runs it
	# off the right edge.
	draw_string(ThemeDB.fallback_font, Vector2(0, 30), "Bezier Path",
			HORIZONTAL_ALIGNMENT_CENTER, 640, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(0, 468), "Drag control points    A: reset",
			HORIZONTAL_ALIGNMENT_CENTER, 640, 13, Color(0.8, 0.8, 0.8))

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_len: float) -> void:
	var total := from.distance_to(to)
	if total < 0.001:
		return
	var dir := (to - from) / total
	var pos := 0.0
	var drawing := true
	while pos < total:
		var next := minf(pos + dash_len, total)
		if drawing:
			draw_line(from + dir * pos, from + dir * next, color, width)
		pos = next
		drawing = !drawing
