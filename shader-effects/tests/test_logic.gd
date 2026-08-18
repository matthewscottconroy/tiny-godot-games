extends Node

# Drives the real effects from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_every_mode_names_a_shader_that_exists()
	_test_every_shader_compiles()
	_test_it_opens_on_the_raw_sprite()
	_test_each_button_attaches_its_shader()
	_test_none_takes_the_shader_off()
	_test_the_dissolve_runs_back_and_forth()
	_test_the_dissolve_reaches_the_shader()
	_test_the_dissolve_restarts_when_reselected()
	await _test_the_pixel_size_stays_usable()
	_test_an_idle_mode_animates_nothing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[shader-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
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

func _run(m: Control, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		m._process(STEP)
		elapsed += STEP

func _material(m: Control) -> ShaderMaterial:
	return m._sprite.material as ShaderMaterial

func _test_every_mode_names_a_shader_that_exists() -> void:
	print("the shader files")
	var m := _make()
	begin_quiet()
	for mode in m.SHADERS:
		var path: String = m.SHADERS[mode]
		if path.is_empty():
			continue
		expect_quiet(ResourceLoader.exists(path), "%s is not there" % path)
	expect(_quiet_failures == 0, "every mode names a shader file that exists")

func _test_every_shader_compiles() -> void:
	print("compiling")
	var m := _make()
	begin_quiet()
	for mode in m.SHADERS:
		var path: String = m.SHADERS[mode]
		if path.is_empty():
			continue
		var shader := load(path) as Shader
		expect_quiet(shader != null and shader.code.contains("shader_type"),
			"%s has no shader code in it" % path)
	expect(_quiet_failures == 0, "every shader loads with code in it")

func _test_it_opens_on_the_raw_sprite() -> void:
	print("on open")
	var m := _make()
	expect(m._mode == m.Mode.NONE, "the demo opens with no effect")
	expect(m._sprite.material == null, "so the sprite is drawn plainly to compare against")

func _test_each_button_attaches_its_shader() -> void:
	print("switching")
	var buttons := {"DissolveBtn": "dissolve", "PixelBtn": "pixelate", "WaveBtn": "wave"}
	begin_quiet()
	for name in buttons:
		var m := _make()
		_press(m, name)
		var material := _material(m)
		expect_quiet(material != null and material.shader != null,
			"%s left the sprite without a shader" % name)
		if material != null and material.shader != null:
			expect_quiet(str(material.shader.resource_path).contains(buttons[name]),
				"%s attached the wrong shader" % name)
	expect(_quiet_failures == 0, "each button attaches its own effect")

func _test_none_takes_the_shader_off() -> void:
	print("going back")
	var m := _make()
	_press(m, "WaveBtn")
	expect(m._sprite.material != null, "an effect is on")
	_press(m, "NoneBtn")
	expect(m._sprite.material == null, "None takes it off rather than leaving it inert")

func _test_the_dissolve_runs_back_and_forth() -> void:
	print("the dissolve")
	var m := _make()
	_press(m, "DissolveBtn")
	expect(is_zero_approx(m._dissolve), "it starts whole")
	_run(m, 0.5)
	expect(m._dissolve > 0.0, "and begins dissolving")

	_run(m, 3.0)
	# It bounces between the two ends rather than stopping at one, so the demo
	# keeps showing the effect without needing another click.
	expect(m._dissolve >= 0.0 and m._dissolve <= 1.0, "the amount stays in range")
	var was: float = m._dissolve
	_run(m, 1.0)
	expect(not is_equal_approx(m._dissolve, was), "and keeps moving")

	var reversed := false
	var previous: float = m._dissolve
	for i in 240:
		m._process(STEP)
		if (m._dissolve - previous) * float(m._dissolve_dir) < 0.0:
			pass
		previous = m._dissolve
		if m._dissolve_dir < 0:
			reversed = true
	expect(reversed, "and turns round at the far end rather than running past it")

func _test_the_dissolve_reaches_the_shader() -> void:
	print("reaching the shader")
	var m := _make()
	_press(m, "DissolveBtn")
	_run(m, 0.5)
	# Held in a variable and never handed over, the sprite would sit there whole
	# while the number climbed.
	expect(is_equal_approx(float(_material(m).get_shader_parameter("dissolve_amount")), m._dissolve),
		"the dissolve amount is handed to the shader")

func _test_the_dissolve_restarts_when_reselected() -> void:
	print("reselecting")
	var m := _make()
	_press(m, "DissolveBtn")
	_run(m, 1.0)
	expect(m._dissolve > 0.0, "part-way through")
	_press(m, "DissolveBtn")
	expect(is_zero_approx(m._dissolve), "choosing it again starts the effect over")
	expect(m._dissolve_dir > 0, "going forwards")

func _test_the_pixel_size_stays_usable() -> void:
	print("pixelate")
	var m := _make()
	_press(m, "PixelBtn")
	begin_quiet()
	var seen := {}
	# Real frames, not hand-called ones: the pixel size is driven by the wall
	# clock, and two hundred synthetic calls inside one millisecond all read
	# the same instant.
	# Held as Variant: the parameter reads back as null until the demo's own
	# _process has written it once, and assigning that to a typed float would
	# abandon this test rather than fail it.
	for i in 200:
		await get_tree().process_frame
		var size: Variant = _material(m).get_shader_parameter("pixel_size")
		if size == null:
			continue
		seen[roundi(size)] = true
		# A pixel size below one divides the image into nothing.
		expect_quiet(float(size) >= 1.0, "the pixel size dropped to %.2f" % size)
	expect(_quiet_failures == 0, "the pixel size never drops below one whole pixel")
	expect(seen.size() > 1, "and it changes over time rather than sitting still")

func _test_an_idle_mode_animates_nothing() -> void:
	print("the other modes")
	var m := _make()
	_press(m, "DissolveBtn")
	_run(m, 0.5)
	# The pixelate clock belongs to pixelate: writing it into whichever shader
	# happens to be attached pokes a parameter the dissolve shader has no use
	# for.
	expect(_material(m).get_shader_parameter("pixel_size") == null,
		"the dissolve shader is not given a pixel size")

	m = _make()
	_press(m, "WaveBtn")
	var before: float = m._dissolve
	_run(m, 1.0)
	# The dissolve clock belongs to the dissolve; leaving it running under
	# another effect means selecting dissolve later starts it part-way through.
	expect(is_equal_approx(m._dissolve, before), "the dissolve does not advance under another effect")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
