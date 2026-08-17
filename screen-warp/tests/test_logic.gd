extends Node

# Drives the real warp controls from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The warp itself is a shader; what is testable is the state it is fed, which is
# what the keys change.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_warp_starts_on()
	_test_the_shader_is_attached_to_the_container()
	_test_w_toggles_the_warp()
	_test_a_disabled_warp_is_fed_no_strength()
	_test_the_strength_keys_move_it_both_ways()
	_test_the_strength_has_limits()
	_test_the_speed_keys_move_it_both_ways()
	_test_the_speed_has_limits()
	_test_key_releases_change_nothing()
	_test_the_world_is_rendered_into_the_viewport()
	_test_the_balls_bounce_inside_the_world()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[screen-warp] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node

func _make() -> Control:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _control(_scene)

## The Control that owns the warp, wherever it sits in the scene.
func _control(root: Node) -> Control:
	if root is Control and root.get("_warp_strength") != null:
		return root
	for child in root.get_children():
		var found := _control(child)
		if found:
			return found
	return null

func _press(m: Control, code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	m._input(e)

func _strength_fed_to_shader(m: Control) -> float:
	m._process(STEP)
	return m._material.get_shader_parameter("strength")

func _test_the_warp_starts_on() -> void:
	print("on open")
	var m := _make()
	expect(m._warp_enabled, "the warp is on, so the demo shows its effect straight away")
	expect(m._warp_strength > 0.0, "with some strength behind it")
	expect(m._warp_speed > 0.0, "and moving")

func _test_the_shader_is_attached_to_the_container() -> void:
	print("the shader")
	var m := _make()
	expect(m._material != null, "there is a shader material")
	expect(m._material.shader != null, "with a shader in it")
	expect((m.get_node("WarpContainer") as CanvasItem).material == m._material,
		"applied to the container the world is drawn into")

func _test_w_toggles_the_warp() -> void:
	print("the W key")
	var m := _make()
	_press(m, KEY_W)
	expect(not m._warp_enabled, "W switches the warp off")
	_press(m, KEY_W)
	expect(m._warp_enabled, "and on again")

func _test_a_disabled_warp_is_fed_no_strength() -> void:
	print("switching it off")
	var m := _make()
	expect(_strength_fed_to_shader(m) > 0.0, "the shader is warping")
	_press(m, KEY_W)
	expect(is_zero_approx(_strength_fed_to_shader(m)),
		"switching off feeds the shader zero strength rather than leaving it warping")
	expect(m._warp_strength > 0.0, "while remembering the setting for when it comes back")

func _test_the_strength_keys_move_it_both_ways() -> void:
	print("strength")
	var m := _make()
	var start: float = m._warp_strength
	_press(m, KEY_EQUAL)
	expect(m._warp_strength > start, "+ increases the warp")
	_press(m, KEY_MINUS)
	expect(is_equal_approx(m._warp_strength, start), "and - takes it back")

func _test_the_strength_has_limits() -> void:
	print("strength limits")
	var m := _make()
	for i in 100:
		_press(m, KEY_EQUAL)
	expect(m._warp_strength <= 0.15, "the warp stops at a maximum rather than tearing the image apart")
	for i in 100:
		_press(m, KEY_MINUS)
	expect(m._warp_strength >= 0.0, "and at zero rather than inverting")

func _test_the_speed_keys_move_it_both_ways() -> void:
	print("speed")
	var m := _make()
	var start: float = m._warp_speed
	_press(m, KEY_UP)
	expect(m._warp_speed > start, "up speeds the ripple up")
	_press(m, KEY_DOWN)
	expect(is_equal_approx(m._warp_speed, start), "and down slows it again")

func _test_the_speed_has_limits() -> void:
	print("speed limits")
	var m := _make()
	for i in 100:
		_press(m, KEY_UP)
	expect(m._warp_speed <= 10.0, "the ripple stops at a maximum speed")
	for i in 100:
		_press(m, KEY_DOWN)
	expect(m._warp_speed >= 0.1, "and never stops dead — a zero speed freezes the effect")

func _test_key_releases_change_nothing() -> void:
	print("key releases")
	var m := _make()
	var strength: float = m._warp_strength
	var enabled: bool = m._warp_enabled
	_press(m, KEY_EQUAL, false)
	_press(m, KEY_W, false)
	expect(is_equal_approx(m._warp_strength, strength), "letting go of + does not warp further")
	expect(m._warp_enabled == enabled, "and letting go of W does not toggle the warp")

func _test_the_world_is_rendered_into_the_viewport() -> void:
	print("the world")
	var m := _make()
	var viewport: SubViewport = m.get_node("WarpContainer/WorldViewport")
	# The world has to live inside the SubViewport, or there is nothing for the
	# shader to distort — it would warp an empty container.
	expect(viewport.get_child_count() > 0, "the world is rendered inside the warped viewport")

func _test_the_balls_bounce_inside_the_world() -> void:
	print("the world's own motion")
	var m := _make()
	var world: Node2D = m.get_node("WarpContainer/WorldViewport").get_child(0)
	var ball: Array = world._balls[0]
	ball[0] = Vector2(ball[3] + 1.0, 240.0)
	ball[1] = Vector2(-200.0, 0.0)
	world._process(STEP)
	expect(ball[1].x > 0.0, "a ball reaching the left edge turns around")
	expect(ball[0].x >= ball[3] - 0.001, "and is nudged back inside")

	# The other three walls, each checked for the nudge landing inside rather
	# than just outside — a sign slip there parks the ball off screen.
	var edges := {
		"right": [Vector2(640.0 - ball[3] - 1.0, 240.0), Vector2(200.0, 0.0)],
		"top": [Vector2(320.0, ball[3] + 1.0), Vector2(0.0, -200.0)],
		"bottom": [Vector2(320.0, 480.0 - ball[3] - 1.0), Vector2(0.0, 200.0)],
	}
	for name in edges:
		var fresh := _make()
		var other: Node2D = fresh.get_node("WarpContainer/WorldViewport").get_child(0)
		var b: Array = other._balls[0]
		b[0] = (edges[name] as Array)[0]
		b[1] = (edges[name] as Array)[1]
		other._process(STEP)
		expect_quiet(b[0].x - b[3] >= -0.001 and b[0].x + b[3] <= 640.001,
			"the %s bounce leaves the ball inside horizontally" % name)
		expect_quiet(b[0].y - b[3] >= -0.001 and b[0].y + b[3] <= 480.001,
			"the %s bounce leaves the ball inside vertically" % name)
	expect(_quiet_failures == 0, "every wall puts the ball back inside the world")

	# And a ball with room around it is left alone.
	var free_scene := _make()
	var free_world: Node2D = free_scene.get_node("WarpContainer/WorldViewport").get_child(0)
	var free_ball: Array = free_world._balls[0]
	free_ball[0] = Vector2(320.0, 240.0)
	free_ball[1] = Vector2(0.0, 200.0)
	free_world._process(STEP)
	expect(free_ball[1].y > 0.0, "a ball in open space keeps going rather than bouncing off nothing")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
