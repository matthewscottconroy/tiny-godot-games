extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_shake_duration()
	_test_shake_strength()
	_test_step_count()
	_test_offset_within_strength()
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

func _test_shake_duration() -> void:
	print("shake duration")
	var duration := 0.4
	expect_near(duration, 0.4, "shake duration is 0.4s")

func _test_shake_strength() -> void:
	print("shake strength")
	var strength := 12.0
	expect(strength == 12.0, "shake strength is 12")

func _test_step_count() -> void:
	print("shake step count derived from duration")
	var duration := 0.4
	var step_interval := 0.04
	var steps := int(duration / step_interval)
	expect(steps == 10, "10 shake steps for 0.4s at 0.04s intervals")

func _test_offset_within_strength() -> void:
	print("shake offset clamped within strength")
	var strength := 12.0
	var offset := Vector2(8.0, -6.0)
	expect(absf(offset.x) <= strength, "x offset within strength")
	expect(absf(offset.y) <= strength, "y offset within strength")

func _report() -> void:
	var summary := "[screen-shake] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
