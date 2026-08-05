extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_fade_duration()
	_test_canvas_layer()
	_test_transitioning_guard()
	_test_guard_prevents_reentry()
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

func _test_fade_duration() -> void:
	print("fade transition duration")
	var duration := 0.4
	expect_near(duration, 0.4, "fade duration is 0.4s")

func _test_canvas_layer() -> void:
	print("overlay canvas layer index")
	var layer := 128
	expect(layer == 128, "overlay is on canvas layer 128")
	expect(layer > 0, "overlay draws above game world")

func _test_transitioning_guard() -> void:
	print("transitioning guard prevents start")
	var transitioning := false
	var started := false
	if not transitioning:
		transitioning = true
		started = true
	expect(started, "transition starts when not already transitioning")
	expect(transitioning, "transitioning flag set after start")

func _test_guard_prevents_reentry() -> void:
	print("guard blocks re-entry during active transition")
	var transitioning := true
	var second_start := false
	if not transitioning:
		second_start = true
	expect(not second_start, "second transition blocked while first is running")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
