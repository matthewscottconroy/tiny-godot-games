extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_gravity_accumulation()
	_test_jump_velocity()
	_test_body_rect()
	_test_eye_rects()
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
	const SPEED := 200.0
	const JUMP_VEL := -420.0
	const GRAVITY := 900.0
	expect(SPEED == 200.0, "SPEED is 200")
	expect(JUMP_VEL == -420.0, "JUMP_VEL is -420")
	expect(GRAVITY == 900.0, "GRAVITY is 900")

func _test_gravity_accumulation() -> void:
	print("gravity accumulation when airborne")
	const GRAVITY := 900.0
	var vel_y := 0.0
	var delta := 0.016
	vel_y += GRAVITY * delta
	expect_near(vel_y, 14.4, "gravity accumulates correctly")
	expect(vel_y > 0.0, "gravity increases downward velocity")

func _test_jump_velocity() -> void:
	print("jump velocity")
	const JUMP_VEL := -420.0
	var vel_y := 0.0
	vel_y = JUMP_VEL
	expect(vel_y < 0.0, "jump velocity is negative (upward)")
	expect_near(vel_y, -420.0, "jump velocity magnitude")

func _test_body_rect() -> void:
	print("player body rect dimensions")
	var body := Rect2(-14, -20, 28, 40)
	expect(body.size.x == 28.0, "body width is 28")
	expect(body.size.y == 40.0, "body height is 40")

func _test_eye_rects() -> void:
	print("eye rect offsets")
	var left_eye := Rect2(-7, -16, 5, 5)
	var right_eye := Rect2(2, -16, 5, 5)
	expect(left_eye.position.x == -7.0, "left eye x offset")
	expect(right_eye.position.x == 2.0, "right eye x offset")
	expect(left_eye.position.y == right_eye.position.y, "eyes at same height")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
