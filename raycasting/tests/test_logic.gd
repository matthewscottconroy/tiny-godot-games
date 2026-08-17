extends Node

# Drives the real ray from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The physics space needs a frame to take the walls before a cast can hit them,
# so this suite awaits one and asks for the frames to do it in tests/frames.

var _pass := 0
var _fail := 0

func _ready() -> void:
	await get_tree().physics_frame
	_test_a_ray_into_open_space_hits_nothing()
	_test_a_ray_at_a_wall_hits_it()
	_test_the_hit_lands_on_the_wall_it_hit()
	_test_the_nearest_wall_stops_the_ray()
	_test_the_ray_is_long_enough_to_cross_the_room()
	_test_the_drawn_line_ends_where_the_ray_does()
	_test_aiming_away_from_a_wall_clears_the_hit()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[raycasting] %d/%d passed" % [_pass, _pass + _fail]
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

## Aim at a point given in world coordinates.
func _aim_world(m: Node2D, world: Vector2) -> void:
	m.aim_at(m.to_local(world))

func _wall(m: Node2D, name: String) -> StaticBody2D:
	return m.get_node(name)

func _test_a_ray_into_open_space_hits_nothing() -> void:
	print("empty space")
	var m := _make()
	expect(not m.is_hitting(), "a ray that has not been aimed yet reports no hit")
	# Straight up from the middle of the room: nothing in the way.
	_aim_world(m, Vector2(320.0, 0.0))
	expect(not m.is_hitting(), "a ray with nothing in its path reports no hit")

func _test_a_ray_at_a_wall_hits_it() -> void:
	print("hitting a wall")
	var m := _make()
	_aim_world(m, _wall(m, "Wall1").global_position)
	expect(m.is_hitting(), "a ray aimed at a wall hits it")

func _test_the_hit_lands_on_the_wall_it_hit() -> void:
	print("where it hit")
	var m := _make()
	var wall := _wall(m, "Wall1")
	_aim_world(m, wall.global_position)
	expect(m.is_hitting(), "hit")
	var world_hit: Vector2 = m.to_global(m.hit_point())
	# Wall1 is the tall thin one to the left, so the hit should be on its near
	# face — level with the ray and just to the right of the wall's centre line.
	expect(world_hit.x > wall.global_position.x, "the hit is on the near face of the wall")
	expect(absf(world_hit.x - wall.global_position.x) < 30.0, "not somewhere past it")
	expect(absf(world_hit.y - 240.0) < 60.0, "and level with the ray, not at the wall's corner")

func _test_the_nearest_wall_stops_the_ray() -> void:
	print("occlusion")
	var m := _make()
	var near := _wall(m, "Wall1")
	# Aiming beyond Wall1, far off to the left: the ray must stop at the wall
	# rather than reporting whatever is behind it.
	_aim_world(m, Vector2(-200.0, 180.0))
	expect(m.is_hitting(), "the wall in the way is hit")
	var world_hit: Vector2 = m.to_global(m.hit_point())
	expect(world_hit.x > near.global_position.x - 20.0, "and the ray stops there, not past it")

func _test_the_ray_is_long_enough_to_cross_the_room() -> void:
	print("reach")
	var m := _make()
	expect(m.RAY_LENGTH > 640.0, "the ray reaches across the whole window")
	_aim_world(m, Vector2(320.0, 0.0))
	var line: Line2D = m.get_node("Line2D")
	var start: Vector2 = line.get_point_position(0)
	var far_end: Vector2 = line.get_point_position(1)
	expect(is_equal_approx(start.distance_to(far_end), m.RAY_LENGTH),
		"and a ray that hits nothing is drawn at its full length from its origin")
	# Aimed at the top of the window, so it has to be drawn upwards — the same
	# length in the opposite direction would look identical to a length check.
	expect(far_end.y < start.y, "in the direction it was aimed, not behind it")

func _test_the_drawn_line_ends_where_the_ray_does() -> void:
	print("the drawn line")
	var m := _make()
	_aim_world(m, _wall(m, "Wall1").global_position)
	expect(m.is_hitting(), "hit")
	var line: Line2D = m.get_node("Line2D")
	expect(line.get_point_position(1).is_equal_approx(m.hit_point()),
		"the line stops at the hit rather than running through the wall")

func _test_aiming_away_from_a_wall_clears_the_hit() -> void:
	print("looking away")
	var m := _make()
	_aim_world(m, _wall(m, "Wall1").global_position)
	expect(m.is_hitting(), "hitting a wall")
	_aim_world(m, Vector2(320.0, 0.0))
	expect(not m.is_hitting(), "aiming back into open space reports no hit again")
