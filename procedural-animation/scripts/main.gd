extends Node2D

const N := 8
const SEG_LEN := 28.0
const ITERS := 8

var _joints: PackedVector2Array
var _base: Vector2 = Vector2(320, 400)
var _target: Vector2 = Vector2(320, 200)

func _ready() -> void:
	_joints.resize(N + 1)
	for i in range(N + 1):
		_joints[i] = _base + Vector2(0, i * SEG_LEN)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_target = event.position

func _fabrik_solve() -> void:
	for _iter in range(ITERS):
		# Forward pass: set head to target, propagate toward tail
		_joints[0] = _target
		for i in range(1, N + 1):
			var dir := (_joints[i] - _joints[i - 1]).normalized()
			_joints[i] = _joints[i - 1] + dir * SEG_LEN
		# Backward pass: set tail to base, propagate toward head
		_joints[N] = _base
		for i in range(N - 1, -1, -1):
			var dir := (_joints[i] - _joints[i + 1]).normalized()
			_joints[i] = _joints[i + 1] + dir * SEG_LEN

func _process(_delta: float) -> void:
	_target = get_global_mouse_position()
	_fabrik_solve()
	queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.06, 0.06, 0.1))

	# Base anchor cross
	var b := _base
	draw_line(b + Vector2(-8, 0), b + Vector2(8, 0), Color(0.6, 0.6, 0.6), 2.0)
	draw_line(b + Vector2(0, -8), b + Vector2(0, 8), Color(0.6, 0.6, 0.6), 2.0)

	# Draw segments from tail to head so head is on top
	for i in range(N - 1, -1, -1):
		var t := float(i) / float(N)
		var width := lerpf(18.0, 4.0, float(i) / float(N))

		# Color gradient: bright cyan-green at head → dark teal at tail
		var seg_color := Color(
			lerp(0.1, 0.0, t),
			lerp(0.9, 0.35, t),
			lerp(0.7, 0.4, t)
		)

		var p0 := _joints[i]
		var p1 := _joints[i + 1]
		var seg_dir := (p1 - p0)
		var seg_len_actual := seg_dir.length()

		if seg_len_actual < 0.001:
			continue

		var perp := seg_dir.normalized().rotated(PI * 0.5)
		var half_w: float = width * 0.5

		# Width tapers along the segment: wide at p0 end, narrower at p1 end
		var w0: float = lerp(18.0, 4.0, float(i) / float(N)) * 0.5
		var w1: float = lerp(18.0, 4.0, float(i + 1) / float(N)) * 0.5

		var poly := PackedVector2Array([
			p0 + perp * w0,
			p0 - perp * w0,
			p1 - perp * w1,
			p1 + perp * w1
		])
		draw_colored_polygon(poly, seg_color)

		# Outline
		draw_polyline(PackedVector2Array([poly[0], poly[3]]), Color(0, 0, 0, 0.3), 1.0)
		draw_polyline(PackedVector2Array([poly[1], poly[2]]), Color(0, 0, 0, 0.3), 1.0)

	# Head circle with eyes
	var head := _joints[0]
	draw_circle(head, 11.0, Color(0.1, 0.9, 0.7))
	draw_circle(head, 9.0, Color(0.15, 1.0, 0.8))

	# Eyes — offset perpendicular to head-to-neck direction
	var neck_dir := Vector2.DOWN
	if N >= 1:
		var diff := _joints[0] - _joints[1]
		if diff.length_squared() > 0.001:
			neck_dir = diff.normalized()
	var eye_perp := neck_dir.rotated(PI * 0.5)
	draw_circle(head + eye_perp * 4.0 + neck_dir * 3.0, 2.5, Color(0.05, 0.05, 0.05))
	draw_circle(head - eye_perp * 4.0 + neck_dir * 3.0, 2.5, Color(0.05, 0.05, 0.05))

	# Title and hints
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, 18), "Procedural Animation (FABRIK)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.5))
	draw_string(font, Vector2(8, 470), "Move mouse to control",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.9, 0.8))
