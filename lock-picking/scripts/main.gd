extends Node2D

const TOLERANCE   := 14.0
const DRAG_SENS   := 0.35
const FILL_SPEED  := 2.5
const DRAIN_SPEED := 4.0

var _correct_angle := 0.0
var _current_angle := 0.0
var _tension       := 0.0
var _unlocked      := false
var _dragging      := false
var _last_x        := 0.0
var _attempts      := 0

func _ready() -> void:
	_new_lock()

func _new_lock() -> void:
	_correct_angle = randf_range(-160.0, 160.0)
	_current_angle = 0.0
	_tension       = 0.0
	_unlocked      = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if _unlocked:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE:
				_attempts += 1
				_new_lock()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_last_x   = event.position.x

	if event is InputEventMouseMotion and _dragging:
		var dx: float = event.position.x - _last_x
		_last_x      = event.position.x
		_current_angle = wrapf(_current_angle + dx * DRAG_SENS, -180.0, 180.0)
		queue_redraw()

func _process(delta: float) -> void:
	if _unlocked:
		return
	var diff := absf(wrapf(_current_angle - _correct_angle, -180.0, 180.0))
	if diff < TOLERANCE:
		_tension = minf(_tension + delta * FILL_SPEED, 1.0)
		if _tension >= 1.0:
			_unlocked = true
	else:
		_tension = maxf(_tension - delta * DRAIN_SPEED, 0.0)
	queue_redraw()

func _draw() -> void:
	var cx := 320.0
	var cy := 240.0
	var r  := 90.0

	# Lock body
	draw_circle(Vector2(cx, cy), r + 20.0, Color(0.25, 0.22, 0.18))
	draw_circle(Vector2(cx, cy), r + 20.0, Color(0.5, 0.45, 0.35), false, 3.0)

	# Cylinder (rotates with _current_angle)
	var angle_rad := deg_to_rad(_current_angle)
	draw_circle(Vector2(cx, cy), r, Color(0.35, 0.32, 0.28))
	var notch_end := Vector2(cx, cy) + Vector2(cos(angle_rad - PI/2.0), sin(angle_rad - PI/2.0)) * r
	draw_line(Vector2(cx, cy), notch_end, Color(0.7, 0.65, 0.5), 4.0)

	# Tension bar
	var bar_x := cx - 140.0
	var bar_y := cy + 130.0
	draw_rect(Rect2(bar_x, bar_y, 280.0, 16.0), Color(0.2, 0.2, 0.2))
	var fill_col := Color(0.9, 0.7, 0.1) if _tension < 0.8 else Color(0.1, 0.9, 0.3)
	draw_rect(Rect2(bar_x, bar_y, 280.0 * _tension, 16.0), fill_col)
	draw_rect(Rect2(bar_x, bar_y, 280.0, 16.0), Color.WHITE, false, 1.5)

	# Labels
	if _unlocked:
		draw_circle(Vector2(cx, cy), r, Color(0.2, 0.8, 0.3, 0.4))
		draw_string(ThemeDB.fallback_font, Vector2(cx - 45, cy + 8),
			"UNLOCKED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.LIME_GREEN)
		draw_string(ThemeDB.fallback_font, Vector2(cx - 70, cy + 170),
			"Space to try another lock", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1,1,1,0.7))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y - 14),
			"Tension", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.6))

	draw_string(ThemeDB.fallback_font, Vector2(8, 20),
		"Drag to rotate lock  |  Attempts: %d" % _attempts,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1,1,1,0.8))
	draw_string(ThemeDB.fallback_font, Vector2(8, 36),
		"Tension fills when at the correct angle",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.5))
