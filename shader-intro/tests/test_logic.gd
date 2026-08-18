extends Node

# Drives the real shader switching from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_every_mode_names_a_shader_that_exists()
	_test_it_opens_on_the_raw_sprite()
	_test_the_sprite_has_something_to_shade()
	_test_each_mode_attaches_its_shader()
	_test_none_takes_the_shader_off_again()
	_test_the_readout_names_the_shader()
	_test_every_shader_compiles()
	await _test_the_flash_fades()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[shader-intro] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Control

func _make() -> Control:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _press(m: Control, name: String) -> void:
	(m.get_node("Buttons/" + name) as Button).pressed.emit()

func _test_every_mode_names_a_shader_that_exists() -> void:
	print("the shader files")
	var m := _make()
	begin_quiet()
	for mode in m.SHADERS:
		var path: String = m.SHADERS[mode]
		if path.is_empty():
			continue
		# A missing file leaves the sprite with a material and no shader, which
		# draws nothing at all rather than drawing plainly.
		expect_quiet(ResourceLoader.exists(path), "%s is not there" % path)
	expect(_quiet_failures == 0, "every mode names a shader file that exists")

func _test_it_opens_on_the_raw_sprite() -> void:
	print("on open")
	var m := _make()
	expect(m.mode == m.ShaderMode.NONE, "the demo opens with no shader")
	expect(m.sprite.material == null, "so the sprite is drawn plainly, to compare against")

func _test_the_sprite_has_something_to_shade() -> void:
	print("the sprite")
	var m := _make()
	expect(m.sprite.texture != null, "there is a texture for the shaders to work on")

func _test_each_mode_attaches_its_shader() -> void:
	print("switching")
	var buttons := {"TintBtn": "tint", "FlashBtn": "flash", "OutlineBtn": "outline"}
	begin_quiet()
	for name in buttons:
		var m := _make()
		_press(m, name)
		var material := m.sprite.material as ShaderMaterial
		expect_quiet(material != null, "%s left the sprite without a shader material" % name)
		if material != null:
			expect_quiet(material.shader != null, "%s attached a material with no shader" % name)
			expect_quiet(str(material.shader.resource_path).contains(buttons[name]),
				"%s attached the wrong shader" % name)
	expect(_quiet_failures == 0, "each button attaches its own shader")

func _test_none_takes_the_shader_off_again() -> void:
	print("going back")
	var m := _make()
	_press(m, "OutlineBtn")
	expect(m.sprite.material != null, "a shader is on")
	_press(m, "NoneBtn")
	# Left attached, the comparison the demo exists to make would be impossible.
	expect(m.sprite.material == null, "None takes the material off rather than leaving it inert")

func _test_the_readout_names_the_shader() -> void:
	print("the readout")
	var m := _make()
	expect(m.mode_label.text.to_lower().contains("no shader"), "the readout says when there is none")
	_press(m, "TintBtn")
	expect(m.mode_label.text.contains("tint"), "and names the shader in use")

func _test_every_shader_compiles() -> void:
	print("compiling")
	var m := _make()
	begin_quiet()
	for mode in m.SHADERS:
		var path: String = m.SHADERS[mode]
		if path.is_empty():
			continue
		var shader := load(path) as Shader
		expect_quiet(shader != null, "%s did not load" % path)
		# An empty shader file loads without complaint and draws nothing.
		expect_quiet(shader != null and shader.code.length() > 0, "%s has no code in it" % path)
		expect_quiet(shader != null and shader.code.contains("shader_type"),
			"%s does not declare a shader_type" % path)
	expect(_quiet_failures == 0, "every shader loads with code in it")

func _test_the_flash_fades() -> void:
	print("the flash")
	var m := _make()
	_press(m, "FlashBtn")
	var material := m.sprite.material as ShaderMaterial
	expect(material != null, "the flash shader is attached")
	await get_tree().process_frame
	await get_tree().process_frame
	var lit: float = material.get_shader_parameter("flash_amount")
	expect(lit > 0.0, "the flash starts lit")
	for i in 120:
		await get_tree().process_frame
		if float(material.get_shader_parameter("flash_amount")) <= 0.0:
			break
	expect(float(material.get_shader_parameter("flash_amount")) <= 0.0,
		"and fades back to nothing rather than staying white")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
