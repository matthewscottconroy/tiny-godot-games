extends Node

# Drives the real remapper from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The InputMap is global, so every test resets the bindings when it is done —
# a leftover remap would change what the next demo's suite sees.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_a_row_per_action()
	_test_the_rows_show_the_current_binding()
	_test_clicking_a_row_listens_for_a_key()
	_test_the_next_key_becomes_the_binding()
	_test_listening_stops_after_one_key()
	_test_keys_pressed_when_not_listening_are_ignored()
	_test_a_remap_replaces_rather_than_adds()
	_test_reset_puts_the_defaults_back()
	_test_reset_cancels_a_pending_rebind()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[input-remapping] %d/%d passed" % [_pass, _pass + _fail]
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
	# _ready leaves the map as it found it; start every test from the defaults.
	_scene._reset_all()
	return _scene

func _press(m: Node2D, code: Key, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	e.echo = echo
	m._unhandled_input(e)

func _bound_keys(action: String) -> Array:
	var keys: Array = []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			keys.append((e as InputEventKey).keycode)
	return keys

func _test_a_row_per_action() -> void:
	print("the list")
	var m := _make()
	expect(m._rows.size() == m.ACTIONS.size(), "there is a row per remappable action")
	for action in m.ACTIONS:
		expect(m._rows.has(action), "including %s" % action)
		expect(InputMap.has_action(action), "which is a real action in the map")

func _test_the_rows_show_the_current_binding() -> void:
	print("the readout")
	var m := _make()
	var button: Button = m._rows["ui_left"]
	expect(button.text.length() > 0, "the row names the key currently bound")
	expect(button.text.to_lower().contains("left"), "which is the default to start with")

func _test_clicking_a_row_listens_for_a_key() -> void:
	print("starting a rebind")
	var m := _make()
	(m._rows["ui_up"] as Button).pressed.emit()
	expect(m._listening_for == "ui_up", "clicking a row waits for a key for that action")
	expect((m._rows["ui_up"] as Button).text.contains("press"), "and says so on the button")

func _test_the_next_key_becomes_the_binding() -> void:
	print("rebinding")
	var m := _make()
	m._start_listen("ui_up")
	_press(m, KEY_W)
	expect(_bound_keys("ui_up").has(KEY_W), "the key pressed becomes the binding")
	expect((m._rows["ui_up"] as Button).text.to_lower().contains("w"), "and the row updates to match")
	m._reset_all()

func _test_listening_stops_after_one_key() -> void:
	print("one key at a time")
	var m := _make()
	m._start_listen("ui_up")
	_press(m, KEY_W)
	expect(m._listening_for.is_empty(), "the rebind ends with the first key")
	_press(m, KEY_J)
	expect(_bound_keys("ui_up").has(KEY_W), "so the next key pressed does not steal the binding")
	expect(not _bound_keys("ui_up").has(KEY_J), "and is not bound to anything")
	m._reset_all()

func _test_keys_pressed_when_not_listening_are_ignored() -> void:
	print("ordinary typing")
	var m := _make()
	var before := _bound_keys("ui_left")
	_press(m, KEY_Z)
	expect(_bound_keys("ui_left") == before, "typing while not rebinding changes nothing")

	m._start_listen("ui_left")
	_press(m, KEY_A, true)
	expect(m._listening_for == "ui_left", "and an auto-repeat echo is not a key press either")
	m._reset_all()

func _test_a_remap_replaces_rather_than_adds() -> void:
	print("replacing")
	var m := _make()
	m._start_listen("ui_up")
	_press(m, KEY_W)
	expect(_bound_keys("ui_up").size() == 1, "an action ends up with exactly one key")
	expect(not _bound_keys("ui_up").has(KEY_UP), "the old binding is gone, not kept alongside")
	m._reset_all()

func _test_reset_puts_the_defaults_back() -> void:
	print("reset")
	var m := _make()
	m._start_listen("ui_up")
	_press(m, KEY_W)
	m._start_listen("ui_left")
	_press(m, KEY_A)
	m._reset_all()
	for action in m.ACTIONS:
		expect(_bound_keys(action) == [m.DEFAULTS[action]],
			"%s is back to its default key" % action)

func _test_reset_cancels_a_pending_rebind() -> void:
	print("reset mid-rebind")
	var m := _make()
	m._start_listen("ui_up")
	m._reset_all()
	expect(m._listening_for.is_empty(), "reset stops waiting for a key")
	_press(m, KEY_W)
	expect(not _bound_keys("ui_up").has(KEY_W), "so the next key pressed does not get captured")
	expect((m._rows["ui_up"] as Button).text.to_lower().contains("up"),
		"and the row shows the default again rather than the prompt")
	m._reset_all()
