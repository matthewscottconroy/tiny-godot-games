extends Node2D

const AGENT_SPEED := 120.0

# Obstacle rectangles (used for both visual and navmesh holes)
const OBSTACLES := [
	Rect2(160, 120, 130, 180),
	Rect2(350, 180, 130, 160),
	Rect2(220, 340, 200, 60),
]

var _agent: CharacterBody2D
var _nav_agent: NavigationAgent2D
var _target_marker: Node2D
var _status_label: Label
var _target_pos := Vector2(560, 100)

func _ready() -> void:
	_agent = $Agent
	_nav_agent = $Agent/NavigationAgent2D
	_target_marker = $TargetMarker
	_status_label = $HUD/StatusLabel

	_build_navmesh()

	# Set initial target after one frame so NavigationServer has time to register
	call_deferred("_set_target", _target_marker.position)

func _build_navmesh() -> void:
	var poly := NavigationPolygon.new()

	# Outer walkable boundary (margin inside the viewport)
	poly.add_outline(PackedVector2Array([
		Vector2(30, 40),
		Vector2(610, 40),
		Vector2(610, 440),
		Vector2(30, 440),
	]))

	# Obstacle holes (inner outlines create non-walkable regions)
	for obs in OBSTACLES:
		var margin := 6.0
		poly.add_outline(PackedVector2Array([
			Vector2(obs.position.x - margin, obs.position.y - margin),
			Vector2(obs.end.x + margin,      obs.position.y - margin),
			Vector2(obs.end.x + margin,      obs.end.y + margin),
			Vector2(obs.position.x - margin, obs.end.y + margin),
		]))

	poly.make_polygons_from_outlines()
	$NavigationRegion2D.navigation_polygon = poly

func _set_target(pos: Vector2) -> void:
	_target_pos = pos
	_target_marker.position = pos
	_nav_agent.target_position = pos
	_status_label.text = "Navigating to (%.0f, %.0f)" % [pos.x, pos.y]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_target(event.position)

func _physics_process(_delta: float) -> void:
	if _nav_agent.is_navigation_finished():
		_agent.velocity = Vector2.ZERO
		_status_label.text = "Arrived at (%.0f, %.0f)" % [_target_pos.x, _target_pos.y]
		return

	var next := _nav_agent.get_next_path_position()
	var dir := next - _agent.global_position
	if dir.length() > 2.0:
		_agent.velocity = dir.normalized() * AGENT_SPEED
	else:
		_agent.velocity = Vector2.ZERO
	_agent.move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.13, 0.15, 0.20))

	# Walkable floor
	draw_rect(Rect2(30, 40, 580, 400), Color(0.22, 0.28, 0.38))

	# Obstacle blocks
	for obs in OBSTACLES:
		draw_rect(obs, Color(0.45, 0.35, 0.28))
		draw_rect(obs, Color(0.6, 0.48, 0.35), false, 2.0)

	# Navigation path
	var path := _nav_agent.get_current_navigation_path()
	if path.size() > 1:
		for i in path.size() - 1:
			draw_line(path[i], path[i + 1], Color(0.3, 0.85, 0.5, 0.6), 2.0)
		for pt in path:
			draw_circle(pt, 3.5, Color(0.3, 0.85, 0.5, 0.8))

	# Target marker
	var tp := _target_marker.position
	draw_circle(tp, 14, Color(1.0, 0.85, 0.1, 0.35))
	draw_circle(tp, 10, Color(1.0, 0.85, 0.1, 0.7))
	draw_circle(tp, 4, Color.WHITE)
	draw_line(tp + Vector2(-14, 0), tp + Vector2(14, 0), Color(1.0, 0.85, 0.1, 0.8), 1.5)
	draw_line(tp + Vector2(0, -14), tp + Vector2(0, 14), Color(1.0, 0.85, 0.1, 0.8), 1.5)

	# Agent
	if is_instance_valid(_agent):
		var ap := _agent.global_position
		draw_circle(ap, 15, Color(0.25, 0.55, 0.95))
		draw_circle(ap, 12, Color(0.35, 0.65, 1.0))
		# Direction indicator
		var dir := _agent.velocity.normalized()
		if dir.length() > 0.1:
			draw_line(ap, ap + dir * 18, Color.WHITE, 2.5)
