extends Node2D

const PARTICLE_COUNT := 80
const GRAVITY := 40.0

var _particles: Array = []
var _wind_angle: float = 0.0
var _wind_strength: float = 60.0
var _time: float = 0.0

# Leaf color palettes
const LEAF_COLORS: Array = [
	Color(0.2, 0.55, 0.15),   # dark green
	Color(0.35, 0.65, 0.1),   # medium green
	Color(0.6, 0.5, 0.1),     # yellow-green
	Color(0.7, 0.4, 0.05),    # golden
	Color(0.55, 0.28, 0.05),  # brown
	Color(0.75, 0.35, 0.1),   # rust
]

func _ready() -> void:
	randomize()
	for i in range(PARTICLE_COUNT):
		_particles.append(_spawn_particle())

func _spawn_particle() -> Dictionary:
	var edge: int = randi() % 2  # 0=top, 1=left
	var pos: Vector2
	if edge == 0:
		pos = Vector2(randf_range(0.0, 640.0), randf_range(-20.0, 0.0))
	else:
		pos = Vector2(randf_range(-20.0, 0.0), randf_range(0.0, 480.0))

	var max_lt: float = randf_range(3.0, 8.0)
	return {
		"pos": pos,
		"vel": Vector2(randf_range(-10.0, 10.0), randf_range(-5.0, 5.0)),
		"size": randf_range(2.0, 6.0),
		"alpha": 1.0,
		"color": LEAF_COLORS[randi() % LEAF_COLORS.size()],
		"lifetime": max_lt,
		"max_lifetime": max_lt,
	}

func _respawn_particle(p: Dictionary) -> void:
	var fresh := _spawn_particle()
	p["pos"] = fresh["pos"]
	p["vel"] = fresh["vel"]
	p["size"] = fresh["size"]
	p["alpha"] = fresh["alpha"]
	p["color"] = fresh["color"]
	p["lifetime"] = fresh["lifetime"]
	p["max_lifetime"] = fresh["max_lifetime"]

func _process(delta: float) -> void:
	_time += delta

	var effective_wind := Vector2(cos(_wind_angle), sin(_wind_angle)) * (_wind_strength + sin(_time * 0.7) * 20.0)

	for p in _particles:
		p["vel"] += effective_wind * delta + Vector2(0.0, GRAVITY * delta)
		p["vel"] *= 0.98
		p["pos"] += p["vel"] * delta
		p["lifetime"] -= delta
		p["alpha"] = p["lifetime"] / p["max_lifetime"]

		var pos: Vector2 = p["pos"]
		if p["lifetime"] <= 0.0 or pos.x > 700.0 or pos.x < -60.0 or pos.y > 540.0 or pos.y < -60.0:
			_respawn_particle(p)

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_wind_angle -= 0.2
			KEY_RIGHT:
				_wind_angle += 0.2
			KEY_UP:
				_wind_strength = minf(_wind_strength + 10.0, 200.0)
			KEY_DOWN:
				_wind_strength = maxf(_wind_strength - 10.0, 0.0)

func _draw() -> void:
	# Sky gradient: three horizontal strips
	draw_rect(Rect2(0, 0, 640, 160), Color(0.4, 0.55, 0.75))
	draw_rect(Rect2(0, 160, 640, 160), Color(0.5, 0.65, 0.8))
	draw_rect(Rect2(0, 320, 640, 160), Color(0.6, 0.72, 0.82))

	# Ground strip
	draw_rect(Rect2(0, 440, 640, 40), Color(0.25, 0.38, 0.18))

	# Draw particles
	for p in _particles:
		var pos: Vector2 = p["pos"]
		var sz: float = p["size"]
		var col: Color = p["color"]
		col.a = clampf(p["alpha"], 0.0, 1.0)
		var vel: Vector2 = p["vel"]

		# Motion blur: draw a short line in direction of velocity
		var vel_len: float = vel.length()
		if vel_len > 5.0:
			var tail: Vector2 = pos - vel.normalized() * minf(vel_len * 0.08, sz * 1.5)
			draw_line(pos, tail, col, sz * 0.6)
		else:
			draw_circle(pos, sz * 0.5, col)

	# Wind direction indicator (top-right)
	var ind_center := Vector2(590.0, 50.0)
	var ind_radius := 30.0
	draw_circle(ind_center, ind_radius, Color(0.0, 0.0, 0.0, 0.4))
	draw_arc(ind_center, ind_radius, 0.0, TAU, 32, Color(0.8, 0.8, 0.8, 0.6), 1.5)

	var wind_dir := Vector2(cos(_wind_angle), sin(_wind_angle))
	var arrow_len: float = remap(_wind_strength, 0.0, 200.0, 5.0, 24.0)
	var arrow_tip := ind_center + wind_dir * arrow_len
	draw_line(ind_center, arrow_tip, Color(1.0, 0.9, 0.2), 2.5)
	# Arrowhead
	var perp := Vector2(-wind_dir.y, wind_dir.x)
	draw_line(arrow_tip, arrow_tip - wind_dir * 6.0 + perp * 4.0, Color(1.0, 0.9, 0.2), 2.0)
	draw_line(arrow_tip, arrow_tip - wind_dir * 6.0 - perp * 4.0, Color(1.0, 0.9, 0.2), 2.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(10, 24), "Wind Effect", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 1.0, 1.0))

	# Wind info
	var deg: float = rad_to_deg(_wind_angle)
	draw_string(ThemeDB.fallback_font, Vector2(10, 46), "Wind: %.0f px/s at %.0f deg" % [_wind_strength, deg], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.9, 0.9))

	# Hints bar
	draw_rect(Rect2(0, 456, 640, 24), Color(0.0, 0.0, 0.0, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(10, 471), "Left/Right: direction   Up/Down: strength", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.85, 0.85))
