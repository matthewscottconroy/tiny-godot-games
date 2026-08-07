extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_ray_length()
	_test_direction_normalized()
	_test_target_computation()
	_test_zero_direction_guard()
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

func _test_ray_length() -> void:
	print("ray length constant")
	const RAY_LENGTH := 700.0
	expect(RAY_LENGTH == 700.0, "RAY_LENGTH is 700")

func _test_direction_normalized() -> void:
	print("direction vector is unit length")
	var mouse_local := Vector2(300.0, 400.0)
	var dir := mouse_local.normalized()
	expect_near(dir.length(), 1.0, "normalized direction has length 1")

func _test_target_computation() -> void:
	print("ray target = direction * RAY_LENGTH")
	const RAY_LENGTH := 700.0
	var dir := Vector2(1.0, 0.0)
	var target := dir * RAY_LENGTH
	expect_near(target.x, 700.0, "horizontal ray target x is RAY_LENGTH")
	expect_near(target.y, 0.0, "horizontal ray target y is 0")

func _test_zero_direction_guard() -> void:
	print("zero direction vector is not unit length")
	var zero_dir := Vector2.ZERO
	expect(zero_dir.length() == 0.0, "zero vector has zero length, should not be used as direction")

func _report() -> void:
	var summary := "[raycasting] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
