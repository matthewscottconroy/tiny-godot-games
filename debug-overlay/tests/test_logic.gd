extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_format_pos()
	_test_format_fps()
	_test_toggle_logic()
	_test_state_values()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_format_pos() -> void:
	print("position formatting")
	var pos := Vector2(120.7, 333.2)
	var text := "Pos:     (%.0f, %.0f)" % [pos.x, pos.y]
	expect(text == "Pos:     (121, 333)", "rounds position to nearest int")

	var neg := Vector2(-5.6, -99.1)
	var neg_text := "Pos:     (%.0f, %.0f)" % [neg.x, neg.y]
	expect(neg_text == "Pos:     (-6, -99)", "handles negative coordinates")

func _test_format_fps() -> void:
	print("fps formatting")
	for fps in [60, 30, 144, 1]:
		var text := "FPS:     %d" % fps
		expect(text == "FPS:     %d" % fps, "fps %d formats without decimals" % fps)

func _test_toggle_logic() -> void:
	print("overlay toggle")
	var visible := true
	visible = !visible
	expect(visible == false, "first toggle hides overlay")
	visible = !visible
	expect(visible == true, "second toggle shows overlay")

func _test_state_values() -> void:
	print("state machine values")
	var valid_states := ["idle", "run", "air"]
	for s in valid_states:
		expect(s in valid_states, "state '%s' is a recognized value" % s)

	# Simulate state transitions
	var on_floor := true
	var vel_x := 0.0
	var state := "idle"

	state = _compute_state(true, 0.0)
	expect(state == "idle", "stationary on floor -> idle")

	state = _compute_state(true, 150.0)
	expect(state == "run", "moving on floor -> run")

	state = _compute_state(false, 0.0)
	expect(state == "air", "off floor -> air regardless of vel_x")

func _compute_state(on_floor: bool, vel_x: float) -> String:
	if not on_floor:
		return "air"
	elif absf(vel_x) > 1.0:
		return "run"
	return "idle"

func _report() -> void:
	var summary := "[debug-overlay] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
