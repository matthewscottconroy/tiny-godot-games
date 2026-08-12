extends Node2D

# Demo driver. The interesting part of this demo is what happens in the *editor*
# — open scenes/main.tscn, select the Ring node, and drag `count` or `radius` in
# the Inspector to watch the children rearrange with the game not running.
#
# At runtime it drives the same exported values from the keyboard so the demo
# still shows something on its own.

@onready var _ring: RingLayout = $Ring
@onready var _status: Label = $HUD/StatusLabel
@onready var _hint: Label = $HUD/HintLabel

func _ready() -> void:
	_hint.text = "1/2 count   3/4 radius   5/6 arc   R rotate   F face outward   " \
		+ "(the point is the Inspector — open this scene in the editor)"
	_rebuild_children()
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: _set_count(_ring.count - 1)
		KEY_2: _set_count(_ring.count + 1)
		KEY_3: _ring.radius -= 10.0
		KEY_4: _ring.radius += 10.0
		KEY_5: _ring.arc -= 0.05
		KEY_6: _ring.arc += 0.05
		KEY_R: _ring.start_angle = fmod(_ring.start_angle + 15.0, 360.0)
		KEY_F: _ring.face_outward = not _ring.face_outward
	_refresh()

func _set_count(n: int) -> void:
	_ring.count = clampi(n, 0, 32)
	_rebuild_children()

# The layout positions whatever children it has, so the demo supplies them.
func _rebuild_children() -> void:
	for child in _ring.get_children():
		child.queue_free()
		_ring.remove_child(child)
	for i in _ring.count:
		var marker := Node2D.new()
		marker.set_script(preload("res://scripts/marker.gd"))
		_ring.add_child(marker)
	_ring._apply()

func _refresh() -> void:
	_status.text = "count %d    radius %.0f    arc %.2f    start %.0f°    facing %s" % [
		_ring.count, _ring.radius, _ring.arc, _ring.start_angle,
		"outward" if _ring.face_outward else "fixed"]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	draw_arc(Vector2(320, 250), _ring.radius, 0, TAU * _ring.arc, 64, Color(1, 1, 1, 0.12), 1.0)
