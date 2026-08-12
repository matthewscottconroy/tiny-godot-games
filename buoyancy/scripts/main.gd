extends Node2D

const WATER_Y := 240.0
const GRAVITY := 500.0
const BUOYANCY := 900.0
const DAMPING := 0.85

var _boxes: Array = []

func _make_boxes() -> Array:
	return [
		{pos = Vector2(60, 80),  vel = Vector2.ZERO, size = Vector2(60, 40), density = 0.3, color = Color(0.2, 0.9, 0.2)},
		{pos = Vector2(160, 80), vel = Vector2.ZERO, size = Vector2(60, 40), density = 0.6, color = Color(0.9, 0.9, 0.2)},
		{pos = Vector2(260, 80), vel = Vector2.ZERO, size = Vector2(60, 40), density = 0.9, color = Color(0.9, 0.6, 0.1)},
		{pos = Vector2(360, 80), vel = Vector2.ZERO, size = Vector2(60, 40), density = 1.1, color = Color(0.9, 0.3, 0.1)},
		{pos = Vector2(460, 80), vel = Vector2.ZERO, size = Vector2(60, 40), density = 1.4, color = Color(0.7, 0.1, 0.1)},
	]

func _ready() -> void:
	_boxes = _make_boxes()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_boxes = _make_boxes()

func _physics_process(delta: float) -> void:
	for box in _boxes:
		# Apply gravity
		box.vel.y += GRAVITY * box.density * delta

		# Calculate submerged depth
		var bottom: float = box.pos.y + box.size.y * 0.5
		var submerged := clampf(bottom - WATER_Y, 0.0, box.size.y)
		var depth_frac: float = submerged / box.size.y

		# Apply buoyancy
		box.vel.y -= BUOYANCY * depth_frac * delta

		# Apply water damping when submerged
		if depth_frac > 0.0:
			var damp_factor: float = pow(DAMPING, delta) * depth_frac + (1.0 - depth_frac)
			box.vel *= damp_factor

		# Update position
		box.pos += box.vel * delta

		# Clamp to screen bounds
		var half_w: float = box.size.x * 0.5
		var half_h: float = box.size.y * 0.5

		if box.pos.x - half_w < 0.0:
			box.pos.x = half_w
			box.vel.x = absf(box.vel.x)
		if box.pos.x + half_w > 640.0:
			box.pos.x = 640.0 - half_w
			box.vel.x = -absf(box.vel.x)
		if box.pos.y - half_h < 0.0:
			box.pos.y = half_h
			box.vel.y = absf(box.vel.y)
		if box.pos.y + half_h > 480.0:
			box.pos.y = 480.0 - half_h
			box.vel.y = -absf(box.vel.y) * 0.3

	queue_redraw()

func _draw() -> void:
	# Sky
	draw_rect(Rect2(0, 0, 640, WATER_Y), Color(0.53, 0.81, 0.98))
	# Water
	draw_rect(Rect2(0, WATER_Y, 640, 480.0 - WATER_Y), Color(0.0, 0.3, 0.7, 0.6))
	# Water ripple line
	draw_line(Vector2(0, WATER_Y), Vector2(640, WATER_Y), Color.WHITE, 2.0)

	var font := ThemeDB.fallback_font
	var font_size := 14

	for box in _boxes:
		var rect := Rect2(box.pos - box.size * 0.5, box.size)
		draw_rect(rect, box.color)
		draw_rect(rect, Color.BLACK, false, 2.0)

		var label := "%.1f" % box.density
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos: Vector2 = box.pos - text_size * 0.5 + Vector2(0, font_size * 0.35)
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)

	# Title and hint
	draw_string(font, Vector2(8, 24), "Buoyancy Demo", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.BLACK)
	draw_string(font, Vector2(8, 46), "Density < 1 floats  Density > 1 sinks  R: reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
