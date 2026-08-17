extends Node

# Drives the real overlay from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_overlay_starts_visible()
	_test_f3_toggles_it()
	_test_the_backtick_key_toggles_it_too()
	_test_other_keys_leave_it_alone()
	_test_a_held_key_toggles_once()
	_test_the_readout_reports_the_player()
	_test_a_hidden_overlay_stops_updating()
	_test_the_player_state_follows_what_it_is_doing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[debug-overlay] %d/%d passed" % [_pass, _pass + _fail]
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

func _panel(m: Node2D) -> Control:
	return m.get_node("CanvasLayer/Panel")

func _label(m: Node2D, name: String) -> Label:
	return m.get_node("CanvasLayer/Panel/VBox/" + name)

func _press(m: Node2D, code: Key, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	e.echo = echo
	m._unhandled_key_input(e)

func _test_the_overlay_starts_visible() -> void:
	print("on open")
	var m := _make()
	expect(m._overlay_visible, "the overlay is on to start with")
	expect(_panel(m).visible, "and its panel is showing")

func _test_f3_toggles_it() -> void:
	print("F3")
	var m := _make()
	_press(m, KEY_F3)
	expect(not m._overlay_visible, "F3 hides the overlay")
	expect(not _panel(m).visible, "and the panel with it")
	_press(m, KEY_F3)
	expect(m._overlay_visible and _panel(m).visible, "and F3 again brings it back")

func _test_the_backtick_key_toggles_it_too() -> void:
	print("the console key")
	var m := _make()
	_press(m, KEY_QUOTELEFT)
	expect(not m._overlay_visible, "the backtick key toggles it as well")

func _test_other_keys_leave_it_alone() -> void:
	print("other keys")
	var m := _make()
	_press(m, KEY_F4)
	_press(m, KEY_A)
	expect(m._overlay_visible, "unrelated keys do not toggle the overlay")

func _test_a_held_key_toggles_once() -> void:
	print("held keys")
	var m := _make()
	_press(m, KEY_F3, true)
	expect(m._overlay_visible, "an auto-repeat echo does not flicker the overlay")

func _test_the_readout_reports_the_player() -> void:
	print("the readout")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	player.global_position = Vector2(123.0, 456.0)
	player.velocity = Vector2(-78.0, 0.0)
	m._process(STEP)
	expect(_label(m, "PosLabel").text.contains("123"), "the position is on screen")
	expect(_label(m, "PosLabel").text.contains("456"), "both parts of it")
	expect(_label(m, "VelLabel").text.contains("-78"), "and so is the velocity")
	expect(_label(m, "FloorLabel").text.contains("false"), "along with whether the player is grounded")
	expect(_label(m, "FPSLabel").text.contains("FPS"), "and the frame rate")

func _test_a_hidden_overlay_stops_updating() -> void:
	print("while hidden")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	player.global_position = Vector2(100.0, 100.0)
	m._process(STEP)
	var shown: String = _label(m, "PosLabel").text

	_press(m, KEY_F3)
	player.global_position = Vector2(500.0, 300.0)
	m._process(STEP)
	# Formatting five labels every frame for a panel nobody can see is the sort
	# of waste a debug overlay should not add to the game it is measuring.
	expect(_label(m, "PosLabel").text == shown, "a hidden overlay does not keep formatting labels")

func _test_the_player_state_follows_what_it_is_doing() -> void:
	print("the state")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(player.is_in_group("player"), "the player registers itself")
	expect(player.state == "idle", "and starts idle")

	player._physics_process(STEP)
	expect(player.state == "air", "off the floor it reports being in the air")

	expect(player.state_for(true, 0.0) == "idle", "standing still on the ground is idle")
	expect(player.state_for(true, 120.0) == "run", "moving along it is running")
	expect(player.state_for(true, -120.0) == "run", "in either direction")
	expect(player.state_for(false, 120.0) == "air", "and in the air it is air, whatever the speed")
	# The threshold sits above zero so a body resting against a wall does not
	# flicker between idle and run.
	expect(player.state_for(true, 0.5) == "idle", "a hair of drift still counts as standing still")

	expect(player.can_jump(true, true), "jumping needs the key and the floor")
	expect(not player.can_jump(true, false), "not the key alone")
	expect(not player.can_jump(false, true), "and not the floor alone")
