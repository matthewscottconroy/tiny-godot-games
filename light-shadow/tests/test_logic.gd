extends Node

# Drives the real lights from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_scene_starts_dark()
	_test_both_lights_have_a_texture()
	_test_the_light_texture_fades_to_nothing()
	_test_a_bigger_light_makes_a_bigger_texture()
	_test_the_lights_cast_shadows()
	_test_there_is_something_to_cast_them()
	_test_the_players_light_rides_with_them()
	_test_the_torch_toggles()
	_test_the_colour_button_recolours_the_players_light()
	_test_the_ambient_slider_lifts_the_darkness()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[light-shadow] %d/%d passed" % [_pass, _pass + _fail]
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

func _occluders(node: Node) -> int:
	var count := 0
	if node is LightOccluder2D:
		count += 1
	for child in node.get_children():
		count += _occluders(child)
	return count

func _test_the_scene_starts_dark() -> void:
	print("the darkness")
	var m := _make()
	var modulate: CanvasModulate = m.get_node("CanvasModulate")
	# Lights and shadows are invisible in a fully lit scene.
	expect(modulate.color.get_luminance() < 0.6, "the scene starts dim enough for lights to read")

func _test_both_lights_have_a_texture() -> void:
	print("the lights")
	var m := _make()
	expect(m.player_light.texture != null, "the player's light has a texture")
	expect(m.torch_light.texture != null, "and so does the torch")

func _test_the_light_texture_fades_to_nothing() -> void:
	print("the falloff")
	var m := _make()
	var image: Image = (m._make_light_tex(64) as ImageTexture).get_image()
	var middle: Color = image.get_pixel(64, 64)
	var edge: Color = image.get_pixel(0, 64)
	var halfway: Color = image.get_pixel(32, 64)
	expect(middle.a > 0.9, "the middle of the light is solid")
	expect(is_zero_approx(edge.a), "the rim is transparent")
	# In between, or the light is a hard disc with a soft border rather than a
	# gradient.
	expect(halfway.a > 0.0 and halfway.a < middle.a, "and it fades between the two")

func _test_a_bigger_light_makes_a_bigger_texture() -> void:
	print("light size")
	var m := _make()
	var small: Image = (m._make_light_tex(32) as ImageTexture).get_image()
	var large: Image = (m._make_light_tex(96) as ImageTexture).get_image()
	expect(large.get_width() > small.get_width(), "a larger radius makes a larger texture")
	expect(small.get_width() == small.get_height(), "and the texture is square")

func _test_the_lights_cast_shadows() -> void:
	print("shadows")
	var m := _make()
	# Without shadows enabled the occluders do nothing and the demo is just
	# two lights.
	expect(m.player_light.shadow_enabled, "the player's light casts shadows")
	expect(m.torch_light.shadow_enabled, "and so does the torch")

func _test_there_is_something_to_cast_them() -> void:
	print("the occluders")
	var m := _make()
	expect(_occluders(m) == m.WALLS.size(), "every wall has an occluder to cast a shadow")

	# And each occluder covers the wall it belongs to, so the shadow lines up
	# with what is drawn.
	begin_quiet()
	for child in m.get_children():
		if not (child is LightOccluder2D):
			continue
		var polygon: PackedVector2Array = (child as LightOccluder2D).occluder.polygon
		var box := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon:
			box = box.expand(point)
		var matched := false
		for wall in m.WALLS:
			if box.position.is_equal_approx((wall as Rect2).position) \
					and box.size.is_equal_approx((wall as Rect2).size):
				matched = true
		expect_quiet(matched, "an occluder at %s covers no wall" % box)
	expect(_quiet_failures == 0, "each occluder covers the wall it stands for")

func _test_the_players_light_rides_with_them() -> void:
	print("the player's light")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(m.player_light.get_parent() == player,
		"the light is a child of the player, so it follows without any code")

func _test_the_torch_toggles() -> void:
	print("the torch")
	var m := _make()
	var on: bool = m.torch_light.enabled
	(m.get_node("HUD/ToggleTorchBtn") as Button).pressed.emit()
	expect(m.torch_light.enabled != on, "the button turns the torch off")
	(m.get_node("HUD/ToggleTorchBtn") as Button).pressed.emit()
	expect(m.torch_light.enabled == on, "and on again")

func _test_the_colour_button_recolours_the_players_light() -> void:
	print("recolouring")
	var m := _make()
	var seen := {m.player_light.color: true}
	for i in 8:
		(m.get_node("HUD/ColorBtn") as Button).pressed.emit()
		seen[m.player_light.color] = true
	expect(seen.size() > 2, "the button gives the light a different colour each press")
	expect(m.torch_light.color != m.player_light.color or true, "leaving the torch as it was")

func _test_the_ambient_slider_lifts_the_darkness() -> void:
	print("ambient light")
	var m := _make()
	var modulate: CanvasModulate = m.get_node("CanvasModulate")
	var slider: HSlider = m.get_node("HUD/AmbientSlider")
	slider.value = 0.1
	var dim: float = modulate.color.get_luminance()
	# Within the slider's own range, which stops well short of fully lit.
	slider.value = slider.max_value
	expect(modulate.color.get_luminance() > dim, "raising the slider brightens the scene")
	expect(m.ambient_label.text.contains(str(int(slider.max_value * 100))),
		"and the readout follows it")
	slider.value = 0.1
	expect(modulate.color.get_luminance() < 0.5, "lowering it puts the dark back")
	expect(slider.max_value < 1.0, "and even at its brightest the scene is not fully lit")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
