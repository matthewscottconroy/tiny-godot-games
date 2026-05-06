extends Node2D

const AGENT_COUNT   := 8
const MAX_SPEED     := 140.0
const MAX_FORCE     := 200.0
const ARRIVE_RADIUS := 60.0    # slow-down radius for seek/arrive
const FLEE_RADIUS   := 150.0
const WANDER_RADIUS := 50.0
const WANDER_DIST   := 80.0
const WANDER_JITTER := 90.0    # radians per second of random angle change

enum Behavior { SEEK, FLEE, WANDER }

var _behavior: Behavior = Behavior.SEEK
var _agents: Array = []        # Array of Dictionaries
var _target: Vector2 = Vector2(320, 240)


func _ready() -> void:
	randomize()
	for i in range(AGENT_COUNT):
		_agents.append({
			"pos":          Vector2(randf_range(40, 600), randf_range(40, 440)),
			"vel":          Vector2(randf_range(-60, 60), randf_range(-60, 60)),
			"wander_angle": randf_range(0, TAU),
			"color":        Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0)),
		})


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_target = event.position
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S: _behavior = Behavior.SEEK
			KEY_F: _behavior = Behavior.FLEE
			KEY_W: _behavior = Behavior.WANDER


func _process(delta: float) -> void:
	for agent in _agents:
		var steering := _compute_steering(agent, delta)
		agent["vel"] += steering * delta
		agent["vel"] = (agent["vel"] as Vector2).limit_length(MAX_SPEED)
		agent["pos"] += agent["vel"] * delta
		# Toroidal wrap
		agent["pos"] = Vector2(
			fposmod(agent["pos"].x, 640.0),
			fposmod(agent["pos"].y, 480.0)
		)
	queue_redraw()


func _compute_steering(agent: Dictionary, delta: float) -> Vector2:
	var pos: Vector2 = agent["pos"]
	var vel: Vector2 = agent["vel"]
	var desired := Vector2.ZERO
	var steering := Vector2.ZERO

	match _behavior:
		Behavior.SEEK:
			var to_target := _target - pos
			var dist := to_target.length()
			var speed := MAX_SPEED
			if dist < ARRIVE_RADIUS:
				speed = MAX_SPEED * (dist / ARRIVE_RADIUS)
			if dist > 0.01:
				desired = to_target.normalized() * speed
			steering = desired - vel
			steering = steering.limit_length(MAX_FORCE)

		Behavior.FLEE:
			var to_target := _target - pos
			var dist := to_target.length()
			if dist < FLEE_RADIUS and dist > 0.01:
				desired = -to_target.normalized() * MAX_SPEED
				steering = desired - vel
				steering = steering.limit_length(MAX_FORCE)
			else:
				# Outside flee radius: decelerate toward zero
				steering = -vel.limit_length(MAX_FORCE)

		Behavior.WANDER:
			# Jitter the wander angle
			agent["wander_angle"] = agent["wander_angle"] + randf_range(-WANDER_JITTER, WANDER_JITTER) * delta
			var wander_angle: float = agent["wander_angle"]
			# Wander target is a point on a circle projected ahead of the agent
			var ahead := vel.normalized() if vel.length() > 0.1 else Vector2(1, 0)
			var wander_target := pos + ahead * WANDER_DIST + Vector2(cos(wander_angle), sin(wander_angle)) * WANDER_RADIUS
			var to_wander := wander_target - pos
			if to_wander.length() > 0.01:
				desired = to_wander.normalized() * MAX_SPEED
			steering = desired - vel
			steering = steering.limit_length(MAX_FORCE)

	return steering


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.08, 0.14))

	# Target indicator (only for SEEK and FLEE)
	if _behavior == Behavior.SEEK or _behavior == Behavior.FLEE:
		var t_color := Color(1.0, 0.9, 0.1, 0.8)
		draw_circle(_target, 8.0, t_color)
		draw_line(_target + Vector2(-10, 0), _target + Vector2(10, 0), t_color, 2.0)
		draw_line(_target + Vector2(0, -10), _target + Vector2(0, 10), t_color, 2.0)

	# Agents
	for agent in _agents:
		var pos: Vector2   = agent["pos"]
		var vel: Vector2   = agent["vel"]
		var col: Color     = agent["color"]

		# Tint color by behavior
		var tinted := col
		match _behavior:
			Behavior.SEEK:   tinted = col.lerp(Color(0.3, 0.7, 1.0), 0.4)
			Behavior.FLEE:   tinted = col.lerp(Color(1.0, 0.3, 0.3), 0.4)
			Behavior.WANDER: tinted = col.lerp(Color(0.4, 1.0, 0.5), 0.4)

		# Draw arrow polygon rotated to face velocity direction
		var angle := vel.angle() if vel.length() > 0.5 else 0.0
		var arrow := PackedVector2Array([
			Vector2(14,  0),   # tip
			Vector2(-8,  7),   # rear-left
			Vector2(-4,  0),   # indent
			Vector2(-8, -7),   # rear-right
		])
		var rotated := PackedVector2Array()
		for pt in arrow:
			rotated.append(pos + pt.rotated(angle))

		draw_polygon(rotated, PackedColorArray([tinted]))
		draw_polyline(rotated, tinted.lightened(0.3), 1.0, true)

	# Behavior label
	var behavior_names := ["SEEK", "FLEE", "WANDER"]
	var bname := behavior_names[_behavior]
	draw_string(ThemeDB.fallback_font, Vector2(540, 22), bname,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 0.3))

	# Title & hints
	draw_string(ThemeDB.fallback_font, Vector2(10, 22), "Steering Behaviors",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(10, 462),
		"S: Seek   F: Flee   W: Wander   Mouse: target",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8, 0.7))
