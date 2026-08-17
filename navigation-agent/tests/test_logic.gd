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
	_test_each_hole_is_the_block_inflated_on_all_four_sides()
	_test_no_part_of_an_obstacle_is_walkable()
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
	var margin: float = m.HOLE_MARGIN
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
	expect(path.size() > 2,
		"the path bends round the blocks rather than running straight at the goal (%d points)"
		% path.size())

	# Not merely outside the blocks: the holes are cut with a margin so the
	# agent clears its own width. A hole cut smaller than the block it covers
	# routes the agent along the wall and scrapes it through the corner.
	var margin: float = m.HOLE_MARGIN
	var closest := 999.0
	begin_quiet()
	for point in path:
		for obstacle in m.OBSTACLES:
			var gap: float = _distance_to_rect(point, obstacle)
			closest = minf(closest, gap)
			expect_quiet(gap >= margin - 0.5,
				"a path point comes within %.1f px of an obstacle at %s" % [gap, point])
	expect(_quiet_failures == 0,
		"the path keeps its margin from every obstacle (closest %.1f px)" % closest)

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

## Every walkable polygon in the baked mesh, in world coordinates.
func _walkable_polygons(mesh: NavigationPolygon) -> Array:
	var vertices := mesh.get_vertices()
	var polygons := []
	for i in mesh.get_polygon_count():
		var shape := PackedVector2Array()
		for index in mesh.get_polygon(i):
			shape.append(vertices[index])
		polygons.append(shape)
	return polygons

func _test_each_hole_is_the_block_inflated_on_all_four_sides() -> void:
	print("the hole outlines")
	var m := _make()
	var mesh := _navmesh(m)
	var margin: float = m.HOLE_MARGIN
	expect(margin > 0.0, "the holes are cut wider than the blocks, to clear the agent")

	# Outline 0 is the room; the rest are the obstacle holes, in order. A corner
	# left un-inflated leaves a wedge of the block walkable, which shows up only
	# for a path that happens to cross that corner.
	begin_quiet()
	for i in m.OBSTACLES.size():
		var rect: Rect2 = m.OBSTACLES[i]
		var expected := Rect2(rect.position - Vector2(margin, margin),
			rect.size + Vector2(margin, margin) * 2.0)
		var outline: PackedVector2Array = mesh.get_outline(i + 1)
		expect_quiet(outline.size() == 4, "hole %d is not a quadrilateral" % i)
		# Corner by corner, not by bounding box: pulling one corner inward
		# leaves the other three defining the same extents, so a box comparison
		# sees nothing wrong.
		var corners := [
			expected.position,
			Vector2(expected.end.x, expected.position.y),
			expected.end,
			Vector2(expected.position.x, expected.end.y),
		]
		for corner in corners:
			var found := false
			for point in outline:
				if (point as Vector2).is_equal_approx(corner):
					found = true
			expect_quiet(found, "hole %d has no corner at %s" % [i, corner])
	expect(_quiet_failures == 0, "every hole is its block inflated by the margin on all four sides")

func _test_no_part_of_an_obstacle_is_walkable() -> void:
	print("the holes in the mesh")
	var m := _make()
	var mesh := _navmesh(m)
	var polygons := _walkable_polygons(mesh)
	expect(polygons.size() > 1, "the mesh is cut into several polygons")

	# Checked against the baked mesh rather than against one route: a hole with
	# a single corner in the wrong place still routes most paths correctly, and
	# leaves a wedge of the block walkable for anything crossing that corner.
	begin_quiet()
	var samples := 6
	for obstacle in m.OBSTACLES:
		var rect: Rect2 = obstacle
		for ix in samples:
			for iy in samples:
				var point := Vector2(
					lerpf(rect.position.x, rect.end.x, float(ix) / float(samples - 1)),
					lerpf(rect.position.y, rect.end.y, float(iy) / float(samples - 1)))
				for shape in polygons:
					expect_quiet(not Geometry2D.is_point_in_polygon(point, shape),
						"%s is inside an obstacle yet walkable" % point)
	expect(_quiet_failures == 0, "no part of any obstacle is left walkable")

## How far a point sits outside a rectangle, or zero if it is inside.
func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(nearest)

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
