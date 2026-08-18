extends Node

# Drives the real preset switching from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_surface_carries_a_shader()
	_test_the_shader_takes_a_preset_and_a_clock()
	_test_the_shader_uses_every_preset()
	_test_it_opens_on_the_first_preset()
	_test_space_cycles_the_presets()
	_test_the_preset_reaches_the_shader()
	_test_the_clock_advances_and_restarts()
	_test_the_readout_names_the_preset()
	_test_a_key_release_changes_nothing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[gpu-particles-custom] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _press(m: Node2D, code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	m._input(e)

func _material(m: Node2D) -> ShaderMaterial:
	return m._rect.material as ShaderMaterial

func _test_the_surface_carries_a_shader() -> void:
	print("the surface")
	var m := _make()
	expect(_material(m) != null, "the surface has a shader material")
	expect(_material(m) != null and _material(m).shader != null, "with a shader in it")

func _test_the_shader_takes_a_preset_and_a_clock() -> void:
	print("the uniforms")
	var m := _make()
	var code: String = _material(m).shader.code
	# Values sent to uniforms the shader never declares go nowhere.
	expect(code.contains("preset"), "the shader declares the preset it is sent")
	expect(code.contains("time_val"), "and the clock it animates on")

func _test_the_shader_uses_every_preset() -> void:
	print("the presets")
	var m := _make()
	var code: String = _material(m).shader.code
	# The last preset is the else branch, so the shader needs one comparison
	# fewer than there are presets. Fewer than that and cycling past a preset
	# shows the same picture under a different name.
	var branches := 0
	for i in m.PRESETS.size():
		if code.contains("preset == %d" % i) or code.contains("preset==%d" % i):
			branches += 1
	expect(branches >= m.PRESETS.size() - 1,
		"the shader tells the presets apart (%d comparisons for %d presets)"
		% [branches, m.PRESETS.size()])

func _test_it_opens_on_the_first_preset() -> void:
	print("on open")
	var m := _make()
	expect(m._preset == 0, "the demo opens on the first preset")
	expect(m.PRESETS.size() > 2, "with several to cycle through")

func _test_space_cycles_the_presets() -> void:
	print("cycling")
	var m := _make()
	for i in range(1, m.PRESETS.size()):
		_press(m, KEY_SPACE)
		expect(m._preset == i, "space steps to preset %d" % i)
	_press(m, KEY_SPACE)
	expect(m._preset == 0, "and comes back round to the first")

func _test_the_preset_reaches_the_shader() -> void:
	print("reaching the shader")
	var m := _make()
	_press(m, KEY_SPACE)
	# Held in a variable and never handed over, the label would change and the
	# picture would not.
	expect(int(_material(m).get_shader_parameter("preset")) == m._preset,
		"the chosen preset is handed to the shader")

func _test_the_clock_advances_and_restarts() -> void:
	print("the clock")
	var m := _make()
	m._process(0.5)
	expect(m._time > 0.0, "the clock runs")
	expect(is_equal_approx(float(_material(m).get_shader_parameter("time_val")), m._time),
		"and is handed to the shader")

	_press(m, KEY_SPACE)
	# Restarted with each preset, so every effect is seen from its beginning
	# rather than joined part-way through.
	expect(is_zero_approx(m._time), "switching preset starts the clock again")

func _test_the_readout_names_the_preset() -> void:
	print("the readout")
	var m := _make()
	begin_quiet()
	for i in m.PRESETS.size():
		expect_quiet(m._label.text.contains(m.PRESETS[m._preset]),
			"the readout does not name preset %d" % m._preset)
		_press(m, KEY_SPACE)
	expect(_quiet_failures == 0, "each preset names itself on screen")

func _test_a_key_release_changes_nothing() -> void:
	print("key releases")
	var m := _make()
	var preset: int = m._preset
	_press(m, KEY_SPACE, false)
	expect(m._preset == preset, "letting go of space does not cycle again")

	_press(m, KEY_Q)
	expect(m._preset == preset, "and an unrelated key does nothing")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
