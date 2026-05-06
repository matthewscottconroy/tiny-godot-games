extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_direction_within_radius()
	_test_direction_zero_when_inactive()
	_test_clamp_prevents_outside_radius()
	_test_direction_normalized_at_edge()
	_test_direction_partial()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)

# --- Simulated joystick logic ---

const BASE_RADIUS := 50.0
const ORIGIN      := Vector2(80.0, 400.0)

class FakeJoystick:
	var direction: Vector2 = Vector2.ZERO
	var _active    := false
	var _knob_pos: Vector2

	func _init() -> void:
		_knob_pos = Vector2(80.0, 400.0)

	func press(pos: Vector2) -> void:
		_active = true
		_update_knob(pos)

	func release() -> void:
		_active = false
		_knob_pos = Vector2(80.0, 400.0)
		direction = Vector2.ZERO

	func move(pos: Vector2) -> void:
		if _active:
			_update_knob(pos)

	func _update_knob(pos: Vector2) -> void:
		var delta := pos - Vector2(80.0, 400.0)
		var clamped := delta.limit_length(50.0)
		_knob_pos = Vector2(80.0, 400.0) + clamped
		direction = clamped / 50.0

func _test_direction_within_radius() -> void:
	print("direction: delta within radius -> direction = delta / BASE_RADIUS")
	var joy := FakeJoystick.new()
	joy.press(Vector2(80.0 + 25.0, 400.0))  # 25px right, half radius
	expect_approx(joy.direction.x, 0.5, "half-right gives direction.x = 0.5")
	expect_approx(joy.direction.y, 0.0, "no vertical component")

func _test_direction_zero_when_inactive() -> void:
	print("direction: zero when not active")
	var joy := FakeJoystick.new()
	expect_approx(joy.direction.length(), 0.0, "direction is zero at start")
	joy.press(Vector2(80.0 + 30.0, 400.0))
	joy.release()
	expect_approx(joy.direction.length(), 0.0, "direction reset to zero on release")

func _test_clamp_prevents_outside_radius() -> void:
	print("clamp: knob stays within BASE_RADIUS")
	var joy := FakeJoystick.new()
	joy.press(Vector2(80.0 + 200.0, 400.0))  # far outside radius
	var knob_delta := joy._knob_pos - Vector2(80.0, 400.0)
	expect_approx(knob_delta.length(), BASE_RADIUS, "knob clamped to BASE_RADIUS distance")

func _test_direction_normalized_at_edge() -> void:
	print("direction: magnitude = 1.0 at full deflection")
	var joy := FakeJoystick.new()
	joy.press(Vector2(80.0 + 200.0, 400.0))  # fully deflected right
	expect_approx(joy.direction.length(), 1.0, "direction length = 1.0 at full deflection")
	expect_approx(joy.direction.x, 1.0, "direction.x = 1.0 when fully right")

func _test_direction_partial() -> void:
	print("direction: diagonal partial deflection")
	var joy := FakeJoystick.new()
	var diag := Vector2(20.0, 20.0)  # within radius (length ~28.3 < 50)
	joy.press(Vector2(80.0, 400.0) + diag)
	expect_approx(joy.direction.x, diag.x / BASE_RADIUS, "diagonal x component correct")
	expect_approx(joy.direction.y, diag.y / BASE_RADIUS, "diagonal y component correct")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
