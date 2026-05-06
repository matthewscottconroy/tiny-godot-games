extends Node2D

const N := 24
const SEG_LEN := 12.0
const GRAVITY := 600.0
const ITERS := 10
const DAMPING := 0.985

const _ANCHOR_IDX := 0
const _ANCHOR_POS := Vector2(320.0, 30.0)

var _pos: PackedVector2Array
var _prev: PackedVector2Array
var _drag: int = -1

func _ready() -> void:
	_pos.resize(N)
	_prev.resize(N)
	_drag = -1
	for i in N:
		var p := _ANCHOR_POS + Vector2(float(i) * SEG_LEN, 0.0)
		_pos[i] = p
		_prev[i] = p

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = -1
			for i in N:
				if i == _ANCHOR_IDX:
					continue
				if _pos[i].distance_to(event.position) < 20.0:
					_drag = i
					break
		else:
			_drag = -1

	if event is InputEventMouseMotion:
		if _drag >= 0:
			_pos[_drag] = event.position
			_prev[_drag] = event.position

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_ready()

func _physics_process(delta: float) -> void:
	# Verlet integration step
	for i in N:
		if i == _ANCHOR_IDX or i == _drag:
			continue
		var vel := (_pos[i] - _prev[i]) * DAMPING
		_prev[i] = _pos[i]
		_pos[i] = _pos[i] + vel + Vector2(0.0, GRAVITY) * delta * delta

	# Constraint relaxation
	for _iter in ITERS:
		_pos[_ANCHOR_IDX] = _ANCHOR_POS
		for i in N - 1:
			var diff := _pos[i + 1] - _pos[i]
			var dist := diff.length()
			if dist < 0.001:
				continue
			var correction := diff * (1.0 - SEG_LEN / dist) * 0.5
			if i != _ANCHOR_IDX:
				_pos[i] = _pos[i] + correction
			if (i + 1) != _drag:
				_pos[i + 1] = _pos[i + 1] - correction

	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.1, 0.1, 0.15))

	# Anchor point
	draw_circle(_ANCHOR_POS, 10.0, Color.GOLD)

	# Rope segments with color gradient
	for i in N - 1:
		var t := float(i) / float(N)
		var col := Color(0.6 + t * 0.4, 0.3, 0.1)
		draw_line(_pos[i], _pos[i + 1], col, 4.0)

	# Rope nodes
	for i in N:
		if i == _ANCHOR_IDX:
			continue
		var r := 6.0 if i == _drag else 4.0
		var col := Color.WHITE if i == _drag else Color(0.7, 0.5, 0.3)
		draw_circle(_pos[i], r, col)

	# UI
	draw_string(font, Vector2(8, 24), "Rope Physics", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(8, 46), "Drag any point  R: reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
