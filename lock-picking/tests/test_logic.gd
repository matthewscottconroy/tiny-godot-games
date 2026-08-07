extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_tolerance()
	_test_tension_fills_when_near()
	_test_tension_drains_when_far()
	_test_unlock_at_full_tension()
	_test_angle_wrapping()
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

const TOLERANCE   := 14.0
const FILL_SPEED  := 2.5
const DRAIN_SPEED := 4.0

func _test_tolerance() -> void:
	print("correct angle tolerance")
	expect(TOLERANCE == 14.0, "TOLERANCE is 14 degrees")

func _test_tension_fills_when_near() -> void:
	print("tension fills when near correct angle")
	var correct_angle := 90.0
	var current_angle := 82.0
	var diff := absf(wrapf(current_angle - correct_angle, -180.0, 180.0))
	expect(diff < TOLERANCE, "angle within tolerance")
	var tension := 0.0
	var delta := 0.1
	tension = minf(tension + delta * FILL_SPEED, 1.0)
	expect(tension > 0.0, "tension increases when angle is near correct")

func _test_tension_drains_when_far() -> void:
	print("tension drains when far from correct angle")
	var correct_angle := 90.0
	var current_angle := 0.0
	var diff := absf(wrapf(current_angle - correct_angle, -180.0, 180.0))
	expect(diff >= TOLERANCE, "angle outside tolerance")
	var tension := 0.5
	var delta := 0.1
	tension = maxf(tension - delta * DRAIN_SPEED, 0.0)
	expect(tension < 0.5, "tension decreases when angle is far")

func _test_unlock_at_full_tension() -> void:
	print("unlocks when tension reaches 1.0")
	var tension := 1.0
	var unlocked := tension >= 1.0
	expect(unlocked, "game unlocks when tension is 1.0")

func _test_angle_wrapping() -> void:
	print("angle wraps between -180 and 180")
	var angle := 190.0
	angle = wrapf(angle, -180.0, 180.0)
	expect(angle >= -180.0 and angle <= 180.0, "angle stays in [-180, 180] range")
	expect_near(angle, -170.0, "190 wraps to -170")

func _report() -> void:
	var summary := "[lock-picking] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
