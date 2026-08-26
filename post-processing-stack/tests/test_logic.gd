extends Node

# Drives the real overlay from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_overlay_covers_the_screen()
	_test_the_overlay_carries_a_shader()
	_test_the_shader_declares_all_three_passes()
	_test_all_three_start_on()
	_test_each_key_toggles_its_own_pass()
	_test_the_toggles_reach_the_shader()
	_test_the_passes_are_independent()
	_test_the_readout_reports_all_three()
	_test_the_scene_underneath_keeps_moving()
	_test_a_key_release_toggles_nothing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## A key release does not toggle an effect.
##
## The handler tests that the event is a key *and* that it is a press. Joined
## with `or`, every mouse move and every key release runs the match — so each
## press toggles twice, once down and once up, and nothing appears to change at
## all.
func _test_a_key_release_toggles_nothing() -> void:
	print("releases")
	var m := _make()
	var before: bool = m._vignette

	var released := InputEventKey.new()
	released.keycode = KEY_1
	released.pressed = false
	m._input(released)
	expect(m._vignette == before,
		"releasing 1 leaves the vignette as it was (%s)" % m._vignette)

	m._input(InputEventMouseMotion.new())
	expect(m._vignette == before, "and a mouse move changes nothing")

	var pressed := InputEventKey.new()
	pressed.keycode = KEY_1
	pressed.pressed = true
	m._input(pressed)
	expect(m._vignette != before, "while pressing it does toggle (%s)" % m._vignette)

	# Down-then-up is one toggle, not two.
	m._input(released)
	expect(m._vignette != before,
		"and letting go does not toggle it back (%s)" % m._vignette)

func _report() -> void:
	var summary := "[post-processing-stack] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
const PASSES := {
	KEY_1: ["vignette_on", "_vignette"],
	KEY_2: ["chromatic_on", "_chroma"],
	KEY_3: ["grade_on", "_grade"],
}

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

func _material(m: Node2D) -> ShaderMaterial:
	return m._overlay.material as ShaderMaterial

func _test_the_overlay_covers_the_screen() -> void:
	print("the overlay")
	var m := _make()
	# A post-processing pass that covers part of the screen grades part of the
	# picture, which reads as a bug rather than an effect.
	expect(m._overlay.size.x >= 640.0 and m._overlay.size.y >= 480.0,
		"the overlay covers the whole window (%s)" % m._overlay.size)

func _test_the_overlay_carries_a_shader() -> void:
	print("the shader")
	var m := _make()
	expect(_material(m) != null, "the overlay has a shader material")
	expect(_material(m) != null and _material(m).shader != null, "with a shader in it")

func _test_the_shader_declares_all_three_passes() -> void:
	print("the uniforms")
	var m := _make()
	var code: String = _material(m).shader.code
	begin_quiet()
	for key in PASSES:
		var uniform: String = (PASSES[key] as Array)[0]
		# A toggle the shader never declares is a switch wired to nothing.
		expect_quiet(code.contains(uniform), "the shader has no %s uniform" % uniform)
	expect(_quiet_failures == 0, "the shader declares every pass the demo toggles")

func _test_all_three_start_on() -> void:
	print("on open")
	var m := _make()
	expect(m._vignette and m._chroma and m._grade,
		"every pass starts on, so the demo shows the full stack")

func _test_each_key_toggles_its_own_pass() -> void:
	print("the keys")
	begin_quiet()
	for key in PASSES:
		var m := _make()
		var field: String = (PASSES[key] as Array)[1]
		var before: bool = m.get(field)
		_press(m, key)
		expect_quiet(m.get(field) != before, "key for %s did not toggle it" % field)
		_press(m, key)
		expect_quiet(m.get(field) == before, "and did not toggle it back")
	expect(_quiet_failures == 0, "each key toggles its own pass and back")

func _test_the_toggles_reach_the_shader() -> void:
	print("reaching the shader")
	begin_quiet()
	for key in PASSES:
		var m := _make()
		var uniform: String = (PASSES[key] as Array)[0]
		var field: String = (PASSES[key] as Array)[1]
		_press(m, key)
		# Flipped in a variable and never handed over, the picture would not
		# change and the readout would lie.
		expect_quiet(_material(m).get_shader_parameter(uniform) == m.get(field),
			"%s was not handed to the shader" % uniform)
	expect(_quiet_failures == 0, "every toggle reaches the shader")

func _test_the_passes_are_independent() -> void:
	print("independence")
	var m := _make()
	_press(m, KEY_1)
	expect(not m._vignette, "the vignette is off")
	expect(m._chroma and m._grade, "and the other two are untouched")
	_press(m, KEY_3)
	expect(not m._vignette and not m._grade, "two off")
	expect(m._chroma, "with the third still on")

func _test_the_readout_reports_all_three() -> void:
	print("the readout")
	var m := _make()
	expect(m._label.text.count("ON") == 3, "the readout shows all three on to start with")
	_press(m, KEY_2)
	expect(m._label.text.count("OFF") == 1, "and one off after a toggle")
	expect(m._label.text.count("ON") == 2, "leaving two on")

func _test_the_scene_underneath_keeps_moving() -> void:
	print("the scene below")
	var m := _make()
	var before: float = m._time
	m._process(0.5)
	# Something has to move under the effect, or there is nothing to see it do.
	expect(m._time > before, "the scene beneath the overlay animates")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
