extends Node2D

## Demo driver. Spawns a handful of SteeringAgents, feeds each the currently
## selected behaviour every frame, and draws them. All steering math lives in
## scripts/steering_agent.gd — this file is only presentation + input.

@export var agent_count := 8

const WORLD_SIZE := Vector2(640, 480)

enum Behavior { SEEK, FLEE, WANDER }

var _behavior: Behavior = Behavior.SEEK
var _agents: Array[SteeringAgent] = []
var _colors: Array[Color] = []          # per-agent tint (presentation only)
var _target := Vector2(320, 240)


func _ready() -> void:
	randomize()
	for i in agent_count:
		var agent := SteeringAgent.new()
		agent.position = Vector2(randf_range(40, 600), randf_range(40, 440))
		agent.velocity = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		agent.wander_angle = randf_range(0, TAU)
		_agents.append(agent)
		_colors.append(Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0)))


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
		var force := _steering_for(agent, delta)
		agent.step(force, delta)
		# Toroidal wrap keeps everyone on screen (demo-specific, not steering).
		agent.position = Vector2(
			fposmod(agent.position.x, WORLD_SIZE.x),
			fposmod(agent.position.y, WORLD_SIZE.y),
		)
	queue_redraw()


func _steering_for(agent: SteeringAgent, delta: float) -> Vector2:
	match _behavior:
		Behavior.SEEK:   return agent.seek(_target)
		Behavior.FLEE:   return agent.flee(_target)
		Behavior.WANDER: return agent.wander(delta)
	return Vector2.ZERO


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.08, 0.08, 0.14))

	# Target indicator (only for SEEK and FLEE)
	if _behavior == Behavior.SEEK or _behavior == Behavior.FLEE:
		var t_color := Color(1.0, 0.9, 0.1, 0.8)
		draw_circle(_target, 8.0, t_color)
		draw_line(_target + Vector2(-10, 0), _target + Vector2(10, 0), t_color, 2.0)
		draw_line(_target + Vector2(0, -10), _target + Vector2(0, 10), t_color, 2.0)

	# Agents, drawn as arrows facing their velocity
	for i in _agents.size():
		var agent := _agents[i]
		var tinted := _colors[i]
		match _behavior:
			Behavior.SEEK:   tinted = tinted.lerp(Color(0.3, 0.7, 1.0), 0.4)
			Behavior.FLEE:   tinted = tinted.lerp(Color(1.0, 0.3, 0.3), 0.4)
			Behavior.WANDER: tinted = tinted.lerp(Color(0.4, 1.0, 0.5), 0.4)

		var angle := agent.velocity.angle() if agent.velocity.length() > 0.5 else 0.0
		var arrow := PackedVector2Array([
			Vector2(14,  0),   # tip
			Vector2(-8,  7),   # rear-left
			Vector2(-4,  0),   # indent
			Vector2(-8, -7),   # rear-right
		])
		var rotated := PackedVector2Array()
		for pt in arrow:
			rotated.append(agent.position + pt.rotated(angle))
		draw_polygon(rotated, PackedColorArray([tinted]))
		draw_polyline(rotated, tinted.lightened(0.3), 1.0, true)

	# Behavior label
	var behavior_names := ["SEEK", "FLEE", "WANDER"]
	draw_string(ThemeDB.fallback_font, Vector2(540, 22), behavior_names[_behavior],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 0.3))

	# Title & hints
	draw_string(ThemeDB.fallback_font, Vector2(10, 22), "Steering Behaviors",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(10, 462),
		"S: Seek   F: Flee   W: Wander   Mouse: target",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8, 0.7))
