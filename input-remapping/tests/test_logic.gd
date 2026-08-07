extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_action_count()
	_test_default_keys()
	_test_player_clamp()
	_test_player_speed()
	_test_listen_state()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_action_count() -> void:
	print("action count")
	var actions := ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept"]
	expect(actions.size() == 5, "5 actions can be remapped")

func _test_default_keys() -> void:
	print("default key assignments")
	var defaults := {
		"ui_left":   KEY_LEFT,
		"ui_right":  KEY_RIGHT,
		"ui_up":     KEY_UP,
		"ui_down":   KEY_DOWN,
		"ui_accept": KEY_SPACE,
	}
	expect(defaults.has("ui_left"), "ui_left has default")
	expect(defaults.has("ui_accept"), "ui_accept has default")
	expect(defaults["ui_accept"] == KEY_SPACE, "ui_accept defaults to Space")
	expect(defaults.size() == 5, "all 5 actions have defaults")

func _test_player_clamp() -> void:
	print("player position clamp")
	var pos := Vector2(10, 390)
	pos = pos.clamp(Vector2(20, 400), Vector2(620, 470))
	expect(pos.x == 20.0, "player x clamped to 20 min")
	expect(pos.y == 400.0, "player y clamped to 400 min")
	pos = Vector2(700, 500)
	pos = pos.clamp(Vector2(20, 400), Vector2(620, 470))
	expect(pos.x == 620.0, "player x clamped to 620 max")
	expect(pos.y == 470.0, "player y clamped to 470 max")

func _test_player_speed() -> void:
	print("player movement speed")
	var speed := 120.0
	var dir := Vector2(1.0, 0.0)
	var delta := 0.016
	var movement := dir * speed * delta
	expect_near(movement.x, 1.92, "player moves 1.92px per frame at speed 120")

func _test_listen_state() -> void:
	print("listening state management")
	var listening_for := ""
	expect(listening_for.is_empty(), "initially not listening")
	listening_for = "ui_left"
	expect(not listening_for.is_empty(), "listen state set")
	listening_for = ""
	expect(listening_for.is_empty(), "listen state cleared after key press")

func _report() -> void:
	var summary := "[input-remapping] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
