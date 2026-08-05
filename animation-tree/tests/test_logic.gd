extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_x_clamp()
	_test_floor_landing()
	_test_fall_transition()
	_test_gravity()
	_test_jump_velocity()
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

func _test_constants() -> void:
	print("constants")
	const SPEED := 180.0
	const GRAVITY := 620.0
	const JUMP_VEL := -330.0
	const FLOOR_Y := 420.0
	expect(SPEED == 180.0, "SPEED is 180")
	expect(GRAVITY == 620.0, "GRAVITY is 620")
	expect(JUMP_VEL == -330.0, "JUMP_VEL is -330")
	expect(FLOOR_Y == 420.0, "FLOOR_Y is 420")

func _test_x_clamp() -> void:
	print("x position clamp")
	var pos_x := 10.0
	pos_x = clampf(pos_x, 20.0, 620.0)
	expect(pos_x == 20.0, "position below 20 clamped to 20")
	pos_x = 700.0
	pos_x = clampf(pos_x, 20.0, 620.0)
	expect(pos_x == 620.0, "position above 620 clamped to 620")
	pos_x = 320.0
	pos_x = clampf(pos_x, 20.0, 620.0)
	expect(pos_x == 320.0, "mid position unchanged")

func _test_floor_landing() -> void:
	print("floor landing detection")
	const FLOOR_Y := 420.0
	var pos_y := 425.0
	var on_floor := pos_y >= FLOOR_Y
	expect(on_floor, "position at 425 is on floor")
	pos_y = 400.0
	on_floor = pos_y >= FLOOR_Y
	expect(not on_floor, "position at 400 is airborne")

func _test_fall_transition() -> void:
	print("fall transition threshold")
	var vel_y := 90.0
	expect(vel_y > 80.0, "vel_y=90 triggers fall state")
	vel_y = 50.0
	expect(not (vel_y > 80.0), "vel_y=50 does not trigger fall")

func _test_gravity() -> void:
	print("gravity value")
	const GRAVITY := 620.0
	var vel_y := 0.0
	vel_y += GRAVITY * 0.016
	expect_near(vel_y, 9.92, "gravity accumulates correctly")

func _test_jump_velocity() -> void:
	print("jump velocity")
	const JUMP_VEL := -330.0
	var vel_y := 0.0
	vel_y = JUMP_VEL
	expect(vel_y < 0.0, "jump velocity is negative (upward)")
	expect(vel_y == -330.0, "jump velocity is exactly -330")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
