extends Control

const BASE_RADIUS := 50.0
const KNOB_RADIUS := 22.0

var _origin: Vector2 = Vector2(80.0, 400.0)
var direction: Vector2 = Vector2.ZERO
var _active := false
var _knob_pos: Vector2

func _ready() -> void:
	_knob_pos = _origin
	custom_minimum_size = Vector2(640, 480)
	mouse_filter = MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = true
			_update_knob(event.position)
		else:
			_active = false
			_knob_pos = _origin
			direction = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion and _active:
		_update_knob(event.position)

func _update_knob(pos: Vector2) -> void:
	var delta := pos - _origin
	var clamped := delta.limit_length(BASE_RADIUS)
	_knob_pos = _origin + clamped
	direction = clamped / BASE_RADIUS
	queue_redraw()

func _draw() -> void:
	# Base ring
	draw_circle(_origin, BASE_RADIUS, Color(0.25, 0.25, 0.25, 0.6))
	draw_arc(_origin, BASE_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35), 2.0)
	# Inner guide rings
	draw_arc(_origin, BASE_RADIUS * 0.5, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.1), 1.0)
	# Knob
	draw_circle(_knob_pos, KNOB_RADIUS, Color(0.85, 0.85, 0.85, 0.95))
	draw_arc(_knob_pos, KNOB_RADIUS, 0.0, TAU, 32, Color(0.5, 0.5, 0.6, 0.8), 1.5)
	# Direction indicator line
	if direction.length() > 0.05:
		draw_line(_origin, _knob_pos, Color(1, 1, 1, 0.5), 1.5)
