extends Node

# Drives the real viewport and world from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	# Headless opens a 64x64 window, and the container sizes the viewport from
	# it — at that size there is no resolution to divide.
	get_window().size = Vector2i(640, 480)
	await get_tree().process_frame
	_test_it_starts_in_pixel_mode()
	await _test_p_toggles_the_resolution()
	await _test_the_pixel_mode_viewport_is_much_smaller()
	_test_the_image_is_stretched_in_both_modes()
	await _test_the_world_matches_the_low_resolution()
	_test_other_keys_leave_the_mode_alone()
	_test_the_player_moves()
	_test_a_diagonal_is_no_faster_than_a_straight_line()
	_test_the_player_wraps_at_every_edge()
	_test_the_obstacles_fit_in_the_world()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[pixel-art-camera] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node

func _make() -> Node:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _viewport(m: Node) -> SubViewport:
	return m.get_node("PixelContainer/PixelViewport")

func _world(m: Node) -> Node2D:
	for child in _viewport(m).get_children():
		if child is Node2D:
			return child
	return null

func _press(m: Node, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

func _test_it_starts_in_pixel_mode() -> void:
	print("on open")
	var m := _make()
	expect(m._pixel_mode, "the demo opens showing its effect")

func _test_p_toggles_the_resolution() -> void:
	print("the P key")
	var m := _make()
	await get_tree().process_frame
	var chunky: Vector2i = _viewport(m).size
	_press(m, KEY_P)
	await get_tree().process_frame
	expect(not m._pixel_mode, "P leaves pixel mode")
	expect(_viewport(m).size != chunky, "and the render resolution changes with it")
	_press(m, KEY_P)
	await get_tree().process_frame
	expect(m._pixel_mode and _viewport(m).size == chunky, "and P again goes back")

func _test_the_pixel_mode_viewport_is_much_smaller() -> void:
	print("resolutions")
	var m := _make()
	await get_tree().process_frame
	var chunky: Vector2i = _viewport(m).size
	_press(m, KEY_P)
	await get_tree().process_frame
	var smooth: Vector2i = _viewport(m).size
	# The chunkiness is rendering at a low resolution and scaling up, so the
	# two modes have to differ by a lot rather than a little.
	expect(chunky.x * 2 < smooth.x, "pixel mode renders at a fraction of the width")
	expect(chunky.y * 2 < smooth.y, "and of the height")
	expect(chunky.x > 0 and chunky.y > 0, "but not at nothing at all")

func _test_the_image_is_stretched_in_both_modes() -> void:
	print("stretching")
	var m := _make()
	var container: SubViewportContainer = m.get_node("PixelContainer")
	expect(container.stretch, "the small image is stretched to fill the window")
	_press(m, KEY_P)
	expect(container.stretch, "and the full-size one still fills it")

func _test_the_world_matches_the_low_resolution() -> void:
	print("the world size")
	var m := _make()
	await get_tree().process_frame
	var world := _world(m)
	expect(world != null, "the world is rendered inside the SubViewport")
	# The world is laid out in the low-resolution space, so the two must agree
	# or the playfield is cropped or floating in empty space.
	expect(is_equal_approx(world.WORLD_W, float(_viewport(m).size.x)),
		"the world is exactly as wide as the pixel-mode viewport")
	expect(is_equal_approx(world.WORLD_H, float(_viewport(m).size.y)), "and as tall")

func _test_other_keys_leave_the_mode_alone() -> void:
	print("other keys")
	var m := _make()
	_press(m, KEY_Q)
	expect(m._pixel_mode, "an unrelated key does not toggle the mode")

func _test_the_player_moves() -> void:
	print("moving")
	var m := _make()
	var world := _world(m)
	world._player_pos = Vector2(80.0, 60.0)
	world.tick(1.0, Vector2.RIGHT)
	expect(is_equal_approx(world._player_pos.x, 80.0 + world.PLAYER_SPEED),
		"a second of walking covers a second's worth of ground")
	expect(is_equal_approx(world._player_pos.y, 60.0), "in the direction asked for only")

func _test_a_diagonal_is_no_faster_than_a_straight_line() -> void:
	print("diagonals")
	var straight := _world(_make())
	straight._player_pos = Vector2(20.0, 20.0)
	straight.tick(0.5, Vector2.RIGHT)
	var straight_distance: float = straight._player_pos.distance_to(Vector2(20.0, 20.0))

	var diagonal := _world(_make())
	diagonal._player_pos = Vector2(20.0, 20.0)
	diagonal.tick(0.5, Vector2(1.0, 1.0))
	var diagonal_distance: float = diagonal._player_pos.distance_to(Vector2(20.0, 20.0))
	expect(is_equal_approx(diagonal_distance, straight_distance),
		"holding two keys travels no faster than holding one")

func _test_the_player_wraps_at_every_edge() -> void:
	print("wrapping")
	var world := _world(_make())
	var cases := {
		"right": [Vector2(world.WORLD_W - 1.0, 60.0), Vector2.RIGHT],
		"left": [Vector2(1.0, 60.0), Vector2.LEFT],
		"bottom": [Vector2(80.0, world.WORLD_H - 1.0), Vector2.DOWN],
		"top": [Vector2(80.0, 1.0), Vector2.UP],
	}
	begin_quiet()
	for name in cases:
		var w := _world(_make())
		w._player_pos = (cases[name] as Array)[0]
		w.tick(0.5, (cases[name] as Array)[1])
		expect_quiet(w._player_pos.x >= 0.0 and w._player_pos.x < w.WORLD_W,
			"walking off the %s edge leaves x inside the world" % name)
		expect_quiet(w._player_pos.y >= 0.0 and w._player_pos.y < w.WORLD_H,
			"walking off the %s edge leaves y inside the world" % name)
	expect(_quiet_failures == 0, "the player wraps at every edge rather than walking off the map")

	var crossed := _world(_make())
	crossed._player_pos = Vector2(crossed.WORLD_W - 1.0, 60.0)
	crossed.tick(0.5, Vector2.RIGHT)
	expect(crossed._player_pos.x < 30.0, "and comes back on the opposite side")

func _test_the_obstacles_fit_in_the_world() -> void:
	print("the scenery")
	var world := _world(_make())
	var bounds := Rect2(0.0, 0.0, world.WORLD_W, world.WORLD_H)
	begin_quiet()
	for obstacle in world.OBSTACLES:
		expect_quiet(bounds.encloses(obstacle["rect"]), "an obstacle sits outside the world")
		expect_quiet(int(obstacle["color_idx"]) < world.OBSTACLE_COLORS.size(),
			"an obstacle asks for a colour that does not exist")
	expect(_quiet_failures == 0, "every obstacle is inside the world and has a colour")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
