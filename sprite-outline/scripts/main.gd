extends Node2D

var _shapes: Array = []
var _selected: int = -1
var _hovered: int = -1

func _ready() -> void:
	_shapes = [
		{"pos": Vector2(100, 120), "radius": 28.0, "color": Color(0.9, 0.2, 0.2)},
		{"pos": Vector2(240, 100), "radius": 22.0, "color": Color(0.2, 0.7, 0.9)},
		{"pos": Vector2(380, 140), "radius": 35.0, "color": Color(0.2, 0.85, 0.3)},
		{"pos": Vector2(140, 280), "radius": 45.0, "color": Color(0.9, 0.6, 0.1)},
		{"pos": Vector2(320, 300), "radius": 30.0, "color": Color(0.7, 0.2, 0.9)},
		{"pos": Vector2(500, 220), "radius": 20.0, "color": Color(0.9, 0.9, 0.2)},
	]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos: Vector2 = event.position
		var nearest: int = -1
		var nearest_dist: float = INF
		for i in range(_shapes.size()):
			var shape = _shapes[i]
			var dist: float = mouse_pos.distance_to(shape["pos"])
			if dist <= shape["radius"] and dist < nearest_dist:
				nearest = i
				nearest_dist = dist
		_hovered = nearest
		queue_redraw()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos: Vector2 = event.position
			var hit: int = -1
			for i in range(_shapes.size()):
				var shape = _shapes[i]
				if mouse_pos.distance_to(shape["pos"]) <= shape["radius"]:
					hit = i
					break
			if hit == _selected:
				_selected = -1
			else:
				_selected = hit
			queue_redraw()

	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			_selected = -1
			queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.12, 0.12, 0.15))

	for i in range(_shapes.size()):
		var shape = _shapes[i]
		var pos: Vector2 = shape["pos"]
		var r: float = shape["radius"]
		var is_hovered: bool = (i == _hovered)
		var is_selected: bool = (i == _selected)

		# Outer outline rings
		if is_selected:
			var yellow = Color(1.0, 0.9, 0.0, 1.0)
			draw_arc(pos, r + 8.0, 0.0, TAU, 64, yellow, 4.0)
			var yellow_inner = Color(1.0, 0.9, 0.0, 0.5)
			draw_arc(pos, r + 4.0, 0.0, TAU, 64, yellow_inner, 2.0)
		elif is_hovered:
			var white_glow = Color(1.0, 1.0, 1.0, 0.5)
			draw_arc(pos, r + 6.0, 0.0, TAU, 64, white_glow, 3.0)

		# Filled circle
		draw_circle(pos, r, shape["color"])

		# Inner outline
		var inner_outline = Color(1.0, 1.0, 1.0, 0.3)
		draw_arc(pos, r - 2.0, 0.0, TAU, 64, inner_outline, 1.5)

		# "SELECTED" label below shape
		if is_selected:
			var label_pos = Vector2(pos.x - 30.0, pos.y + r + 14.0)
			draw_string(ThemeDB.fallback_font, label_pos, "SELECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.0))

	# Info panel background
	draw_rect(Rect2(0, 440, 640, 40), Color(0.0, 0.0, 0.0, 0.6))

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(10, 20), "Sprite Outline", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 1.0, 1.0))

	# Hint text
	draw_string(ThemeDB.fallback_font, Vector2(10, 458), "Click to select, hover to highlight  |  ESC to deselect", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8))
