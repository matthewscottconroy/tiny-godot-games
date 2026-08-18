extends Node

# Drives the real distortion from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The wobble is a shader; what is testable is the state fed to it and the way
# the demo steps through its settings.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_shader_is_on_the_container()
	_test_the_world_is_inside_the_viewport()
	_test_it_starts_on_a_visible_setting()
	_test_the_strength_reaches_the_shader()
	_test_the_settings_run_from_off_to_heavy()
	_test_stepping_through_the_settings()
	_test_the_list_wraps_both_ways()
	_test_the_readout_names_the_setting()
	_test_the_player_jumps_only_from_the_floor()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[screen-distortion] %d/%d passed" % [_pass, _pass + _fail]
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

func _fed_strength(m: Node2D) -> float:
	return m._mat.get_shader_parameter("strength")

func _test_the_shader_is_on_the_container() -> void:
	print("the shader")
	var m := _make()
	expect(m._mat != null, "there is a shader material")
	expect(m._mat.shader != null, "with a shader in it")
	expect((m.get_node("SubViewportContainer") as CanvasItem).material == m._mat,
		"applied to the container the world is drawn through")

func _test_the_world_is_inside_the_viewport() -> void:
	print("the world")
	var m := _make()
	var viewport: SubViewport = m.get_node("SubViewportContainer/SubViewport")
	# Outside the SubViewport there is nothing for the shader to distort: it
	# would wobble an empty rectangle.
	expect(viewport.get_child_count() > 0, "the world is rendered inside the distorted viewport")
	expect(m._player.get_parent() == viewport or viewport.is_ancestor_of(m._player),
		"including the player")

func _test_it_starts_on_a_visible_setting() -> void:
	print("on open")
	var m := _make()
	# Opening on "Off" would show a demo that appears to do nothing.
	expect(_fed_strength(m) > 0.0, "the demo opens with the distortion switched on")

func _test_the_strength_reaches_the_shader() -> void:
	print("reaching the shader")
	var m := _make()
	expect(is_equal_approx(_fed_strength(m), m.STRENGTHS[m._strength_idx]),
		"the chosen strength is handed to the shader rather than only stored")

func _test_the_settings_run_from_off_to_heavy() -> void:
	print("the settings")
	var m := _make()
	expect(m.STRENGTHS.size() == m.LABELS.size(), "every strength has a label")
	expect(is_zero_approx(m.STRENGTHS[0]), "the first setting is properly off")
	var rising := true
	for i in m.STRENGTHS.size() - 1:
		if m.STRENGTHS[i] >= m.STRENGTHS[i + 1]:
			rising = false
	expect(rising, "and each one after it is stronger than the last")

func _test_stepping_through_the_settings() -> void:
	print("stepping")
	var m := _make()
	m._strength_idx = 0
	m._apply_strength()
	_act(m, "ui_right")
	expect(m._strength_idx == 1, "right steps to the next setting")
	expect(is_equal_approx(_fed_strength(m), m.STRENGTHS[1]), "and the shader follows")
	_act(m, "ui_left")
	expect(m._strength_idx == 0, "left steps back")
	expect(is_equal_approx(_fed_strength(m), m.STRENGTHS[0]), "and the shader follows that too")

func _test_the_list_wraps_both_ways() -> void:
	print("wrapping")
	var forward := _make()
	forward._strength_idx = 0
	for i in forward.STRENGTHS.size():
		_act(forward, "ui_right")
	expect(forward._strength_idx == 0, "stepping past the end comes back to the start")

	var backward := _make()
	backward._strength_idx = 0
	_act(backward, "ui_left")
	expect(backward._strength_idx == backward.STRENGTHS.size() - 1,
		"and stepping back from the first lands on the last")

func _test_the_readout_names_the_setting() -> void:
	print("the readout")
	var m := _make()
	var label: Label = m.get_node("CanvasLayer/StrLabel")
	begin_quiet()
	for i in m.STRENGTHS.size():
		m._strength_idx = i
		m._apply_strength()
		expect_quiet(label.text.contains(m.LABELS[i]),
			"setting %d is not named on screen" % i)
	expect(_quiet_failures == 0, "each setting names itself in the readout")

func _test_the_player_jumps_only_from_the_floor() -> void:
	print("the player")
	var m := _make()
	expect(m._player.can_jump(true, true), "pressing jump on the floor jumps")
	expect(not m._player.can_jump(true, false), "pressing it in mid-air does not")
	expect(not m._player.can_jump(false, true), "and standing on the floor is not enough")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
