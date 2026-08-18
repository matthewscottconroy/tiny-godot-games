extends Node

# Drives the real palette swap from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_sprite_is_generated()
	_test_the_source_colours_are_in_the_texture()
	_test_it_starts_on_the_first_palette()
	_test_the_shader_is_given_the_palette()
	_test_stepping_forward_and_back()
	_test_the_list_wraps_both_ways()
	_test_every_palette_is_distinct()
	_test_the_readout_names_the_palette()
	_test_the_swap_only_changes_the_shader()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[palette-swap] %d/%d passed" % [_pass, _pass + _fail]
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

func _act(m: Node2D, action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	m._input(e)

## Compare two colours as an 8-bit image stores them.
##
## An RGBA8 image quantises each channel to 1/255, so 0.12 comes back as
## 0.1176 and exact comparison never matches.
func _same_colour(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 \
		and absf(a.b - b.b) < 0.01 and absf(a.a - b.a) < 0.01

func _shader_colour(m: Node2D, name: String) -> Color:
	return m._mat.get_shader_parameter(name)

func _test_the_sprite_is_generated() -> void:
	print("the sprite")
	var m := _make()
	expect(m._texture != null, "the character is built in code, not loaded from a file")
	expect(m._texture.get_width() > 0 and m._texture.get_height() > 0, "with a real size")
	expect(m._sprite.texture == m._texture, "and shown on the sprite")
	# Mipmaps on pixel art blur exactly the edges the style depends on.
	expect(not (m._texture.get_image() as Image).has_mipmaps(),
		"and without mipmaps, which would smear the pixels")

func _test_the_source_colours_are_in_the_texture() -> void:
	print("the source colours")
	var m := _make()
	var image: Image = m._texture.get_image()
	var body := Color(0.12, 0.56, 1.00)
	var armor := Color(1.00, 0.84, 0.00)
	var found_body := false
	var found_armor := false
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if _same_colour(pixel, body):
				found_body = true
			elif _same_colour(pixel, armor):
				found_armor = true
	# The shader looks for these exact colours to replace. If the artwork does
	# not contain them, the swap finds nothing and the character never changes.
	expect(found_body, "the texture contains the body colour the shader looks for")
	expect(found_armor, "and the armour colour")

func _test_it_starts_on_the_first_palette() -> void:
	print("on open")
	var m := _make()
	expect(m._palette_idx == 0, "the demo opens on the first palette")
	expect(m.PALETTES.size() > 2, "with several to cycle through")

func _test_the_shader_is_given_the_palette() -> void:
	print("reaching the shader")
	var m := _make()
	var first: Dictionary = m.PALETTES[0]
	# Held in a dictionary and never handed over, the palettes would be a list
	# nothing reads.
	expect(_shader_colour(m, "body_dst").is_equal_approx(first["body"]),
		"the shader is given the body colour")
	expect(_shader_colour(m, "armor_dst").is_equal_approx(first["armor"]),
		"and the armour colour")

func _test_stepping_forward_and_back() -> void:
	print("stepping")
	var m := _make()
	_act(m, "ui_right")
	expect(m._palette_idx == 1, "right steps to the next palette")
	expect(_shader_colour(m, "body_dst").is_equal_approx(m.PALETTES[1]["body"]),
		"and the shader follows")
	_act(m, "ui_left")
	expect(m._palette_idx == 0, "left steps back")

func _test_the_list_wraps_both_ways() -> void:
	print("wrapping")
	var forward := _make()
	for i in forward.PALETTES.size():
		_act(forward, "ui_right")
	expect(forward._palette_idx == 0, "stepping past the end comes back to the start")

	var backward := _make()
	_act(backward, "ui_left")
	# The + PALETTES.size() before the modulo is what stops this being -1.
	expect(backward._palette_idx == backward.PALETTES.size() - 1,
		"and stepping back from the first lands on the last")

func _test_every_palette_is_distinct() -> void:
	print("the palettes")
	var m := _make()
	var bodies := {}
	var names := {}
	begin_quiet()
	for palette in m.PALETTES:
		bodies[palette["body"]] = true
		names[palette["name"]] = true
		expect_quiet(not (palette["body"] as Color).is_equal_approx(palette["armor"]),
			"palette %s uses one colour for both parts" % palette["name"])
	expect(_quiet_failures == 0, "every palette tells its two parts apart")
	expect(bodies.size() == m.PALETTES.size(), "no two palettes share a body colour")
	expect(names.size() == m.PALETTES.size(), "and each has its own name")

func _test_the_readout_names_the_palette() -> void:
	print("the readout")
	var m := _make()
	var label: Label = m.get_node("CanvasLayer/PalLabel")
	expect(label.text.contains(m.PALETTES[0]["name"]), "the label names the palette")
	# "(1/5)" rather than "1/", which a negative index would also satisfy.
	expect(label.text.contains("(1/%d)" % m.PALETTES.size()),
		"and counts it from one, as a person would")
	_act(m, "ui_right")
	expect(label.text.contains(m.PALETTES[1]["name"]), "and follows a change")
	expect(label.text.contains("(2/%d)" % m.PALETTES.size()), "counting on with it")

func _test_the_swap_only_changes_the_shader() -> void:
	print("what a swap touches")
	var m := _make()
	var image_before: PackedByteArray = (m._texture.get_image() as Image).get_data()
	_act(m, "ui_right")
	_act(m, "ui_right")
	# The point of the technique: one texture, recoloured by the shader, rather
	# than a copy of the artwork per palette.
	expect((m._texture.get_image() as Image).get_data() == image_before,
		"the artwork itself is never rewritten")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
