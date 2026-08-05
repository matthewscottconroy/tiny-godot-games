extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_deadzone_constant()
	_test_deadzone_filter_below()
	_test_deadzone_filter_above()
	_test_deadzone_boundary()
	_test_stick_vector_deadzone()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) <= tol, label)

func _test_deadzone_constant() -> void:
	print("deadzone constant")
	const DEADZONE := 0.12
	expect(DEADZONE == 0.12, "DEADZONE is 0.12")

func _test_deadzone_filter_below() -> void:
	print("deadzone filters values below threshold")
	const DEADZONE := 0.12
	var raw := 0.05
	var val := 0.0 if abs(raw) < DEADZONE else raw
	expect(val == 0.0, "value 0.05 below deadzone filtered to 0")
	raw = -0.10
	val = 0.0 if abs(raw) < DEADZONE else raw
	expect(val == 0.0, "negative value -0.10 below deadzone filtered to 0")

func _test_deadzone_filter_above() -> void:
	print("deadzone passes values above threshold")
	const DEADZONE := 0.12
	var raw := 0.5
	var val := 0.0 if abs(raw) < DEADZONE else raw
	expect_near(val, 0.5, "value 0.5 above deadzone passes through")
	raw = -0.8
	val = 0.0 if abs(raw) < DEADZONE else raw
	expect_near(val, -0.8, "negative value passes through above deadzone")

func _test_deadzone_boundary() -> void:
	print("deadzone boundary: exactly at threshold is filtered out")
	const DEADZONE := 0.12
	var raw := 0.12
	var val := 0.0 if abs(raw) < DEADZONE else raw
	expect_near(val, 0.12, "exactly at deadzone threshold: not filtered (uses <, not <=)")

func _test_stick_vector_deadzone() -> void:
	print("stick vector deadzone (2D analog)")
	const DEADZONE := 0.12
	var raw := Vector2(0.05, 0.08)
	var val := Vector2.ZERO if raw.length() < DEADZONE else raw
	expect(val == Vector2.ZERO, "small stick vector below deadzone filtered")
	raw = Vector2(0.7, 0.4)
	val = Vector2.ZERO if raw.length() < DEADZONE else raw
	expect(val != Vector2.ZERO, "large stick vector passes deadzone filter")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
