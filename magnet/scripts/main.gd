extends Node2D

const GRAVITY := 200.0
const MAGNET_STRENGTH := 18000.0
const MAX_FORCE := 600.0
const BALL_R := 12.0
const DAMPING := 0.992
const MIN_DIST := 30.0
const MAGNET_GRAB_RADIUS := 30.0
const BALL_COUNT := 10

var _magnet_pos: Vector2 = Vector2(320, 200)
var _attract: bool = true
var _dragging_magnet: bool = false
var _balls: Array = []

func _ready() -> void:
	_reset_balls()

func _reset_balls() -> void:
	_balls.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var colors := [
		Color(0.75, 0.75, 0.78),
		Color(0.82, 0.80, 0.76),
		Color(0.70, 0.72, 0.75),
		Color(0.80, 0.78, 0.80),
	]
	for i in range(BALL_COUNT):
		_balls.append({
			"pos": Vector2(rng.randf_range(40.0, 600.0), rng.randf_range(260.0, 430.0)),
			"vel": Vector2.ZERO,
			"color": colors[i % colors.size()],
		})

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.position.distance_to(_magnet_pos) < MAGNET_GRAB_RADIUS:
					_dragging_magnet = true
			else:
				_dragging_magnet = false
	elif event is InputEventMouseMotion:
		if _dragging_magnet:
			_magnet_pos = event.position
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_A:
			_attract = !_attract
		elif event.keycode == KEY_R:
			_reset_balls()

func _physics_process(delta: float) -> void:
	for ball in _balls:
		# Gravity
		ball["vel"].y += GRAVITY * delta

		# Magnet force
		var diff: Vector2 = _magnet_pos - ball["pos"]
		var dist := maxf(diff.length(), MIN_DIST)
		var force_magnitude := MAGNET_STRENGTH / (dist * dist)
		force_magnitude = minf(force_magnitude, MAX_FORCE)
		var force_dir: Vector2 = diff.normalized() if _attract else -diff.normalized()
		ball["vel"] += force_dir * force_magnitude * delta

		# Damping
		ball["vel"] *= pow(DAMPING, delta * 60.0)

		# Move
		ball["pos"] += ball["vel"] * delta

		# Bounce off edges
		if ball["pos"].x - BALL_R < 0.0:
			ball["pos"].x = BALL_R
			ball["vel"].x = absf(ball["vel"].x) * 0.5
		elif ball["pos"].x + BALL_R > 640.0:
			ball["pos"].x = 640.0 - BALL_R
			ball["vel"].x = -absf(ball["vel"].x) * 0.5
		if ball["pos"].y - BALL_R < 0.0:
			ball["pos"].y = BALL_R
			ball["vel"].y = absf(ball["vel"].y) * 0.5
		elif ball["pos"].y + BALL_R > 480.0:
			ball["pos"].y = 480.0 - BALL_R
			ball["vel"].y = -absf(ball["vel"].y) * 0.5

	queue_redraw()

func _draw() -> void:
	# Force field lines
	var field_color := Color(0.9, 0.3, 0.2, 0.18) if _attract else Color(0.2, 0.4, 0.9, 0.18)
	var num_lines := 8
	for i in range(num_lines):
		var angle := (float(i) / float(num_lines)) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		for seg in range(6):
			var r0 := 40.0 + seg * 22.0
			var r1 := r0 + 16.0
			var alpha := 0.22 * (1.0 - float(seg) / 6.0)
			var c := Color(field_color.r, field_color.g, field_color.b, alpha)
			if _attract:
				draw_line(_magnet_pos + dir * r1, _magnet_pos + dir * r0, c, 1.5)
			else:
				draw_line(_magnet_pos + dir * r0, _magnet_pos + dir * r1, c, 1.5)

	# Draw balls with velocity indicators
	for ball in _balls:
		draw_circle(ball["pos"], BALL_R, ball["color"])
		draw_arc(ball["pos"], BALL_R, 0, TAU, 24, Color(0.4, 0.4, 0.45), 1.5)
		# Velocity vector
		var vel_len: float = ball["vel"].length()
		if vel_len > 5.0:
			var vel_draw: Vector2 = ball["vel"].normalized() * minf(vel_len * 0.1, 20.0)
			draw_line(ball["pos"], ball["pos"] + vel_draw, Color(1, 1, 0, 0.6), 1.5)

	# Draw magnet
	var magnet_col := Color(0.9, 0.2, 0.15) if _attract else Color(0.2, 0.35, 0.95)
	var magnet_col_light := magnet_col.lightened(0.3)
	# Horseshoe shape: two arms + arc
	var arm_w := 12.0
	var arm_h := 26.0
	var gap := 10.0
	# Left arm
	draw_rect(Rect2(_magnet_pos + Vector2(-gap - arm_w, -arm_h * 0.5), Vector2(arm_w, arm_h)), magnet_col)
	# Right arm
	draw_rect(Rect2(_magnet_pos + Vector2(gap, -arm_h * 0.5), Vector2(arm_w, arm_h)), magnet_col)
	# Top arc connecting arms
	draw_arc(_magnet_pos + Vector2(0, -arm_h * 0.5), gap + arm_w * 0.5, PI, TAU, 24, magnet_col, arm_w)
	# Pole tips
	draw_rect(Rect2(_magnet_pos + Vector2(-gap - arm_w, arm_h * 0.5 - 6.0), Vector2(arm_w, 6.0)), Color(0.9, 0.9, 0.2))
	draw_rect(Rect2(_magnet_pos + Vector2(gap, arm_h * 0.5 - 6.0), Vector2(arm_w, 6.0)), Color(0.9, 0.9, 0.2))
	# Outline
	draw_arc(_magnet_pos + Vector2(0, -arm_h * 0.5), gap + arm_w * 0.5, PI, TAU, 24, magnet_col_light, 2.0)

	# Mode label
	var mode_text := "ATTRACT" if _attract else "REPEL"
	var mode_col := Color(0.9, 0.3, 0.2) if _attract else Color(0.2, 0.5, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(320, 55), mode_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, mode_col)

	# Title and hints
	draw_string(ThemeDB.fallback_font, Vector2(320, 30), "Magnet", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(320, 468), "Drag magnet    A: toggle attract/repel    R: reset", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.8, 0.8, 0.8))
