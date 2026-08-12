extends Node2D

# Demo driver. The plugin itself only does anything inside the editor — enable
# "Ring Tools" in Project Settings → Plugins and a dock appears on the left,
# with RingSpawner available in the Add Node dialog.
#
# At runtime this drives the same custom node from the keyboard so the demo
# still shows the thing the plugin creates.

@onready var _spawner: Node2D = $RingSpawner
@onready var _status: Label = $HUD/StatusLabel
@onready var _hint: Label = $HUD/HintLabel

func _ready() -> void:
	_hint.text = "1/2 points   3/4 skip   5/6 radius     " \
		+ "Enable 'Ring Tools' in Project Settings → Plugins to get the dock and the custom node."
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: _spawner.points = maxi(_spawner.points - 1, 3)
		KEY_2: _spawner.points = mini(_spawner.points + 1, 32)
		KEY_3: _spawner.skip = maxi(_spawner.skip - 1, 1)
		KEY_4: _spawner.skip = mini(_spawner.skip + 1, 8)
		KEY_5: _spawner.radius -= 10.0
		KEY_6: _spawner.radius += 10.0
	_refresh()

func _refresh() -> void:
	_status.text = "points %d    skip %d    radius %.0f    vertices drawn %d" % [
		_spawner.points, _spawner.skip, _spawner.radius, _spawner.polygon().size()]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
