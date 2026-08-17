extends Node

# Drives the real navigation from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The pathfinding is NavigationServer2D's; what this checks is that the demo
# hands it a usable map and follows what comes back. The server needs a couple
# of frames to register a region, so the suite waits for them.

var _pass := 0
var _fail := 0

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_test_the_navmesh_is_built()
	_test_the_obstacles_are_holes_in_it()
	_test_the_obstacles_do_not_touch()
	await _test_the_agent_is_given_a_target()
	await _test_clicking_sets_a_new_target()
	await _test_a_path_goes_around_an_obstacle()
	await _test_the_agent_walks_the_path()
	await _test_the_agent_stops_when_it_arrives()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[navigation-agent] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _settle(frames: int = 6) -> void:
	for i in frames:
		await get_tree().physics_frame

func _navmesh(m: Node2D) -> NavigationPolygon:
	return (m.get_node("NavigationRegion2D") as NavigationRegion2D).navigation_polygon

## Somewhere open, on the far side of the obstacles from the agent.
func _far_corner(m: Node2D) -> Vector2:
	return Vector2(560.0, 400.0)

func _test_the_navmesh_is_built() -> void:
	print("the navmesh")
	var m := _make()
	var mesh := _navmesh(m)
	expect(mesh != null, "the region has a navigation polygon")
	expect(mesh != null and mesh.get_polygon_count() > 0,
		"which baked into actual polygons rather than staying a list of outlines")

func _test_the_obstacles_are_holes_in_it() -> void:
	print("the holes")
	var m := _make()
	var mesh := _navmesh(m)
	# One outline for the room plus one per obstacle: without the holes the
	# agent would walk straight through the blocks.
	expect(mesh.get_outline_count() == m.OBSTACLES.size() + 1,
		"there is an outline for the room and one per obstacle")

func _test_the_obstacles_do_not_touch() -> void:
	print("obstacle spacing")
	var m := _make()
	# The demo's own comment says overlapping hole outlines break the partition
	# step, and each rect is inflated before being cut out.
	var margin := 6.0
	begin_quiet()
	for i in m.OBSTACLES.size():
		for j in range(i + 1, m.OBSTACLES.size()):
			var a: Rect2 = (m.OBSTACLES[i] as Rect2).grow(margin)
			var b: Rect2 = (m.OBSTACLES[j] as Rect2).grow(margin)
			expect_quiet(not a.intersects(b), "obstacles %d and %d overlap once inflated" % [i, j])
	expect(_quiet_failures == 0, "no two obstacle holes overlap once inflated")

func _test_the_agent_is_given_a_target() -> void:
	print("the first target")
	var m := _make()
	await _settle()
	expect(m._nav_agent.target_position != Vector2.ZERO, "the agent is given somewhere to go")
	expect(m._nav_agent.target_position == m._target_marker.position,
		"which is where the marker is")

func _test_clicking_sets_a_new_target() -> void:
	print("clicking")
	var m := _make()
	await _settle()
	var target := _far_corner(m)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = target
	m._unhandled_input(e)
	expect(m._target_pos == target, "clicking sets the destination")
	expect(m._target_marker.position == target, "moves the marker there")
	expect(m._nav_agent.target_position == target, "and tells the agent")
	expect((m.get_node("HUD/StatusLabel") as Label).text.contains("Navigating"),
		"with the readout saying so")

func _test_a_path_goes_around_an_obstacle() -> void:
	print("routing")
	var m := _make()
	await _settle()
	m._set_target(_far_corner(m))
	await _settle()

	var path: PackedVector2Array = m._nav_agent.get_current_navigation_path()
	expect(path.size() > 1, "the agent has a path to follow")

	# No leg of the path may cut through a block — that is what the holes buy.
	begin_quiet()
	for point in path:
		for obstacle in m.OBSTACLES:
			expect_quiet(not (obstacle as Rect2).has_point(point),
				"a path point sits inside an obstacle at %s" % point)
	expect(_quiet_failures == 0, "no point on the path stands inside an obstacle")

func _test_the_agent_walks_the_path() -> void:
	print("walking")
	var m := _make()
	await _settle()
	var start: Vector2 = m._agent.global_position
	m._set_target(_far_corner(m))
	await _settle(60)
	expect(m._agent.global_position.distance_to(start) > 10.0, "the agent sets off")
	expect(m._agent.global_position.distance_to(_far_corner(m)) < start.distance_to(_far_corner(m)),
		"and gets closer to where it was sent")

func _test_the_agent_stops_when_it_arrives() -> void:
	print("arriving")
	var m := _make()
	await _settle()
	# Sent somewhere it is already standing: it should report arrival rather
	# than jittering on the spot.
	m._set_target(m._agent.global_position)
	await _settle(10)
	expect(m._agent.velocity == Vector2.ZERO, "an agent at its destination stops")
	expect((m.get_node("HUD/StatusLabel") as Label).text.contains("Arrived"),
		"and says it has arrived")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
