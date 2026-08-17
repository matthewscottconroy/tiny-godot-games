extends Node

# Drives the real spawner from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_empty()
	_test_clicking_spawns_a_body()
	_test_a_mouse_release_spawns_nothing()
	_test_a_body_defaults_to_a_box()
	_test_bodies_spawn_where_they_were_clicked()
	_test_shapes_alternate()
	_test_every_body_has_a_collision_shape()
	_test_the_shape_matches_what_is_drawn()
	_test_colours_cycle()
	_test_the_counter_follows()
	await _test_the_bodies_fall_and_land()
	await _test_the_walls_hold_them_in()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[rigid-body] %d/%d passed" % [_pass, _pass + _fail]
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

func _bodies(m: Node2D) -> Array[RigidBody2D]:
	var found: Array[RigidBody2D] = []
	for child in m.get_children():
		if child is RigidBody2D:
			found.append(child)
	return found

func _click(m: Node2D, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	m._unhandled_input(e)

func _shape_of(body: RigidBody2D) -> Shape2D:
	for child in body.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).shape
	return null

func _test_it_starts_empty() -> void:
	print("before clicking")
	var m := _make()
	expect(_bodies(m).is_empty(), "nothing has been spawned yet")
	expect(m.count == 0, "and nothing counted")

func _test_clicking_spawns_a_body() -> void:
	print("spawning")
	var m := _make()
	_click(m, Vector2(200.0, 100.0))
	expect(_bodies(m).size() == 1, "a click spawns a body")
	expect(m.count == 1, "and counts it")
	expect(_bodies(m)[0].gravity_scale > 0.0, "which falls under gravity")

func _test_a_mouse_release_spawns_nothing() -> void:
	print("releases")
	var m := _make()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(200.0, 100.0)
	m._unhandled_input(release)
	# Otherwise every click spawns twice: once going down and once coming up.
	expect(_bodies(m).is_empty(), "letting go of the button spawns nothing")

	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(200.0, 100.0)
	m._unhandled_input(motion)
	expect(_bodies(m).is_empty(), "and neither does moving the mouse across the window")

func _test_a_body_defaults_to_a_box() -> void:
	print("the body script")
	var body: RigidBody2D = load("res://scripts/physics_body.gd").new()
	expect(not body.is_circle, "a body drawn before it is configured is a box, not a circle")
	body.free()

func _test_bodies_spawn_where_they_were_clicked() -> void:
	print("placement")
	var m := _make()
	_click(m, Vector2(200.0, 100.0))
	_click(m, Vector2(400.0, 150.0))
	expect(_bodies(m)[0].position == Vector2(200.0, 100.0), "the first lands where it was clicked")
	expect(_bodies(m)[1].position == Vector2(400.0, 150.0), "and so does the second")

func _test_shapes_alternate() -> void:
	print("shapes")
	var m := _make()
	for i in 4:
		_click(m, Vector2(100.0 + i * 60.0, 100.0))
	var bodies := _bodies(m)
	# Alternating gives a mix on screen without any randomness to explain.
	expect(not bodies[0].is_circle, "the first body is a box")
	expect(bodies[1].is_circle, "the second is round")
	expect(bodies[0].is_circle == bodies[2].is_circle, "and the pattern alternates from there")

func _test_every_body_has_a_collision_shape() -> void:
	print("collision")
	var m := _make()
	begin_quiet()
	for i in 4:
		_click(m, Vector2(100.0 + i * 60.0, 100.0))
	for body in _bodies(m):
		# A RigidBody2D without a shape falls through everything and logs
		# nothing about it.
		expect_quiet(_shape_of(body) != null, "a body was spawned with no collision shape")
	expect(_quiet_failures == 0, "every body has a shape to collide with")

func _test_the_shape_matches_what_is_drawn() -> void:
	print("shape and drawing")
	var m := _make()
	for i in 4:
		_click(m, Vector2(100.0 + i * 60.0, 100.0))
	begin_quiet()
	for body in _bodies(m):
		var shape := _shape_of(body)
		if body.is_circle:
			expect_quiet(shape is CircleShape2D, "a round body has a box collider")
		else:
			expect_quiet(shape is RectangleShape2D, "a square body has a round collider")
	expect(_quiet_failures == 0, "each body collides with the shape it is drawn as")

func _test_colours_cycle() -> void:
	print("colours")
	var m := _make()
	var wanted: int = m.colors.size() + 1
	for i in wanted:
		_click(m, Vector2(100.0 + i * 40.0, 100.0))
	var bodies := _bodies(m)
	expect(bodies[0].body_color != bodies[1].body_color, "consecutive bodies differ in colour")
	expect(bodies[m.colors.size()].body_color == bodies[0].body_color,
		"and the palette comes back round rather than running off the end")

func _test_the_counter_follows() -> void:
	print("the readout")
	var m := _make()
	_click(m, Vector2(200.0, 100.0))
	_click(m, Vector2(300.0, 100.0))
	expect((m.get_node("CountLabel") as Label).text.contains("2"), "the label counts the bodies")

func _test_the_bodies_fall_and_land() -> void:
	print("falling")
	var m := _make()
	_click(m, Vector2(320.0, 100.0))
	var body := _bodies(m)[0]
	var start: float = body.position.y
	for i in 90:
		await get_tree().physics_frame
	expect(body.position.y > start, "a spawned body falls")
	expect(body.position.y < 470.0, "and the floor stops it rather than letting it drop out")

func _test_the_walls_hold_them_in() -> void:
	print("the walls")
	var m := _make()
	_click(m, Vector2(320.0, 100.0))
	var body := _bodies(m)[0]
	body.linear_velocity = Vector2(2000.0, 0.0)
	for i in 90:
		await get_tree().physics_frame
	expect(body.position.x < 640.0, "a body thrown at the wall stays in the room")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
