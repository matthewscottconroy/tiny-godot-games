extends Node2D

const NUM_PARTICLES := 24
const SEG_LENGTH    := 16.0
const GRAVITY       := Vector2(0.0, 500.0)
const ITERATIONS    := 12
const ANCHOR        := Vector2(320.0, 60.0)

var _pos:  PackedVector2Array
var _prev: PackedVector2Array
var _drag_idx := -1

func _ready() -> void:
	_pos.resize(NUM_PARTICLES)
	_prev.resize(NUM_PARTICLES)
	for i in NUM_PARTICLES:
		var p := ANCHOR + Vector2(float(i) * 2.0, float(i) * SEG_LENGTH)
		_pos[i]  = p
		_prev[i] = p

func _physics_process(delta: float) -> void:
	var dt := minf(delta, 0.05)

	for i in range(1, NUM_PARTICLES):
		var vel := _pos[i] - _prev[i]
		_prev[i] = _pos[i]
		_pos[i] += vel + GRAVITY * dt * dt

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse := get_viewport().get_mouse_position()
		if _drag_idx == -1:
			for i in range(1, NUM_PARTICLES):
				if _pos[i].distance_to(mouse) < 20.0:
					_drag_idx = i
					break
		if _drag_idx != -1:
			_pos[_drag_idx] = mouse

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_idx = -1

	for _iter in ITERATIONS:
		_pos[0] = ANCHOR
		for i in range(NUM_PARTICLES - 1):
			var dv   := _pos[i + 1] - _pos[i]
			var dist := dv.length()
			if dist < 0.0001:
				continue
			var corr := dv * ((dist - SEG_LENGTH) / dist * 0.5)
			if i > 0:
				_pos[i] += corr
			_pos[i + 1] -= corr
		_pos[0] = ANCHOR

	queue_redraw()

func _draw() -> void:
	for i in range(NUM_PARTICLES - 1):
		var t   := float(i) / float(NUM_PARTICLES)
		var col := Color(0.8 - t * 0.3, 0.5 - t * 0.2, 0.2)
		draw_line(_pos[i], _pos[i + 1], col, 3.0)
	for i in NUM_PARTICLES:
		var col := Color.WHITE if i == 0 else Color(0.9, 0.7, 0.3)
		draw_circle(_pos[i], 4.0, col)
	draw_circle(ANCHOR, 8.0, Color.WHITE)
	draw_circle(ANCHOR, 5.0, Color(0.2, 0.4, 0.8))
