extends Node

# Drives the real lighting from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_surface_carries_a_shader()
	_test_the_shader_takes_a_light_position()
	_test_the_light_follows_the_cursor()
	_test_the_light_is_given_uv_not_pixels()
	_test_the_corners_map_to_the_corners()
	_test_r_puts_the_light_back_in_the_middle()
	_test_other_keys_leave_it_alone()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[normal-map-lighting] %d/%d passed" % [_pass, _pass + _fail]
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

func _material(m: Node2D) -> ShaderMaterial:
	return m._rect.material as ShaderMaterial

func _light_uv(m: Node2D) -> Vector2:
	return _material(m).get_shader_parameter("light_uv")

func _viewport_size(m: Node2D) -> Vector2:
	return m.get_viewport_rect().size

func _test_the_surface_carries_a_shader() -> void:
	print("the surface")
	var m := _make()
	expect(_material(m) != null, "the surface has a shader material")
	expect(_material(m) != null and _material(m).shader != null, "with a shader in it")

func _test_the_shader_takes_a_light_position() -> void:
	print("the uniform")
	var m := _make()
	var code: String = _material(m).shader.code
	# A light position the shader never declares is a value sent into nothing.
	expect(code.contains("light_uv"), "the shader declares the light position it is sent")
	expect(code.contains("NORMAL_MAP") or code.contains("normal"),
		"and reads a normal map, which is the point of the demo")

func _test_the_light_follows_the_cursor() -> void:
	print("following the cursor")
	var m := _make()
	var size := _viewport_size(m)
	m.aim_light(size * 0.25)
	var near_corner := _light_uv(m)
	m.aim_light(size * 0.75)
	var far_corner := _light_uv(m)
	expect(far_corner.x > near_corner.x, "moving the cursor right moves the light right")
	expect(far_corner.y > near_corner.y, "and down moves it down")

func _test_the_light_is_given_uv_not_pixels() -> void:
	print("the coordinates")
	var m := _make()
	var size := _viewport_size(m)
	m.aim_light(size * 0.5)
	var middle := _light_uv(m)
	# The shader works in 0..1. Handing it raw pixels puts the light hundreds
	# of units off the surface, where it lights nothing at all.
	expect(middle.is_equal_approx(Vector2(0.5, 0.5)),
		"the middle of the screen is the middle of the surface (%s)" % middle)

func _test_the_corners_map_to_the_corners() -> void:
	print("the corners")
	var m := _make()
	var size := _viewport_size(m)
	m.aim_light(Vector2.ZERO)
	expect(_light_uv(m).is_equal_approx(Vector2.ZERO), "the top-left corner maps to 0,0")
	m.aim_light(size)
	expect(_light_uv(m).is_equal_approx(Vector2.ONE), "and the bottom-right to 1,1")

func _test_r_puts_the_light_back_in_the_middle() -> void:
	print("reset")
	var m := _make()
	m.aim_light(Vector2.ZERO)
	expect(_light_uv(m).is_equal_approx(Vector2.ZERO), "the light is off in a corner")
	var e := InputEventKey.new()
	e.keycode = KEY_R
	e.pressed = true
	m._input(e)
	expect(_light_uv(m).is_equal_approx(Vector2(0.5, 0.5)), "R centres it again")

func _test_other_keys_leave_it_alone() -> void:
	print("other keys")
	var m := _make()
	m.aim_light(Vector2.ZERO)
	var e := InputEventKey.new()
	e.keycode = KEY_Q
	e.pressed = true
	m._input(e)
	expect(_light_uv(m).is_equal_approx(Vector2.ZERO), "an unrelated key does not move the light")

	var release := InputEventKey.new()
	release.keycode = KEY_R
	release.pressed = false
	m._input(release)
	expect(_light_uv(m).is_equal_approx(Vector2.ZERO), "and neither does letting go of R")
