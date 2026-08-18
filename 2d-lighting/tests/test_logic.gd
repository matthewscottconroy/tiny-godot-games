extends Node

# Drives the real lights from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_scene_starts_dark()
	_test_every_light_has_a_texture()
	_test_the_light_texture_fades_out()
	_test_the_lights_are_different_colours()
	_test_the_players_light_follows_them()
	_test_the_player_stays_on_screen()
	_test_a_diagonal_is_no_faster()
	_test_l_turns_the_darkness_off()
	_test_the_size_keys_have_a_floor()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[2d-lighting] %d/%d passed" % [_pass, _pass + _fail]
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

func _press(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

func _lights(m: Node2D) -> Array[PointLight2D]:
	var found: Array[PointLight2D] = []
	for child in m.get_children():
		if child is PointLight2D:
			found.append(child)
	return found

func _test_the_scene_starts_dark() -> void:
	print("the darkness")
	var m := _make()
	var modulate: CanvasModulate = m.get_node("CanvasModulate")
	# Without a dark CanvasModulate the lights have nothing to light: the scene
	# is already fully bright and every lamp is invisible.
	expect(modulate.color.get_luminance() < 0.5, "the scene starts dark enough for lights to show")
	expect(m._lights_on, "with the lighting on")

func _test_every_light_has_a_texture() -> void:
	print("the lamps")
	var m := _make()
	var lights := _lights(m)
	expect(lights.size() > 2, "there are several lights")
	begin_quiet()
	for light in lights:
		# A PointLight2D with no texture casts nothing at all.
		expect_quiet(light.texture != null, "a light has no texture and casts nothing")
	expect(_quiet_failures == 0, "every light was given the generated texture")

func _test_the_light_texture_fades_out() -> void:
	print("the falloff")
	var m := _make()
	var texture := m._make_light_texture() as GradientTexture2D
	expect(texture.fill == GradientTexture2D.FILL_RADIAL, "the light is a radial gradient")
	var gradient := texture.gradient
	# Opaque in the middle, transparent at the rim — a light that does not fade
	# is a hard-edged disc.
	expect(gradient.sample(0.0).a > gradient.sample(1.0).a, "bright in the middle, fading outward")
	expect(is_equal_approx(gradient.sample(1.0).a, 0.0), "to nothing at the edge")

func _test_the_lights_are_different_colours() -> void:
	print("colours")
	var m := _make()
	var colours := {}
	for light in _lights(m):
		colours[light.color] = true
	expect(colours.size() > 1, "the lamps are different colours, so their overlap is visible")

func _test_the_players_light_follows_them() -> void:
	print("the player's light")
	var m := _make()
	m.tick(1.0, Vector2.RIGHT)
	expect(m._player_light.position.is_equal_approx(m._player_pos),
		"the light sits on the player wherever they go")

func _test_the_player_stays_on_screen() -> void:
	print("the edges")
	var m := _make()
	for i in 60:
		m.tick(0.2, Vector2(1.0, 1.0))
	expect(m._player_pos.x <= 640.0 and m._player_pos.y <= 480.0,
		"walking into the far corner stops at the edge")
	for i in 120:
		m.tick(0.2, Vector2(-1.0, -1.0))
	expect(m._player_pos.x >= 0.0 and m._player_pos.y >= 0.0, "and the near corner too")

func _test_a_diagonal_is_no_faster() -> void:
	print("diagonals")
	var straight := _make()
	var straight_start: Vector2 = straight._player_pos
	straight.tick(0.5, Vector2.RIGHT)
	var diagonal := _make()
	var diagonal_start: Vector2 = diagonal._player_pos
	diagonal.tick(0.5, Vector2(1.0, 1.0))
	expect(is_equal_approx(diagonal._player_pos.distance_to(diagonal_start),
		straight._player_pos.distance_to(straight_start)),
		"holding two keys travels no faster than one")

func _test_l_turns_the_darkness_off() -> void:
	print("the L key")
	var m := _make()
	var modulate: CanvasModulate = m.get_node("CanvasModulate")
	var dark: float = modulate.color.get_luminance()
	_press(m, KEY_L)
	expect(not m._lights_on, "L turns the lighting off")
	expect(modulate.color.get_luminance() > dark, "which brightens the whole scene to show the difference")
	_press(m, KEY_L)
	expect(m._lights_on and is_equal_approx(modulate.color.get_luminance(), dark),
		"and L again puts the dark back")

func _test_the_size_keys_have_a_floor() -> void:
	print("light size")
	var m := _make()
	var start: float = m._player_light.texture_scale
	_press(m, KEY_EQUAL)
	expect(m._player_light.texture_scale > start, "+ makes the light bigger")
	_press(m, KEY_MINUS)
	expect(is_equal_approx(m._player_light.texture_scale, start), "and - smaller")
	for i in 40:
		_press(m, KEY_MINUS)
	# A texture_scale of zero or below makes the light vanish and cannot be
	# grown back by eye.
	expect(m._player_light.texture_scale > 0.0, "the light never shrinks away to nothing")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
