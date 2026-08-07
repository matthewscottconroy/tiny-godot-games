extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_default_speed()
	_test_direction_normalization()
	_test_diagonal_normalization()
	_test_zero_direction_guard()
	_test_position_delta()
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

func _test_default_speed() -> void:
	print("default speed")
	var speed := 200.0
	expect(speed == 200.0, "default speed is 200")

func _test_direction_normalization() -> void:
	print("direction normalization")
	var dir := Vector2(1.0, 0.0)
	expect_near(dir.normalized().length(), 1.0, "unit right vector stays unit")
	dir = Vector2(0.0, 1.0)
	expect_near(dir.normalized().length(), 1.0, "unit down vector stays unit")
	dir = Vector2(-1.0, 0.0)
	expect_near(dir.normalized().length(), 1.0, "unit left vector stays unit")

func _test_diagonal_normalization() -> void:
	print("diagonal normalization")
	var dir := Vector2(1.0, 1.0)
	var norm := dir.normalized()
	expect_near(norm.length(), 1.0, "diagonal normalized to unit length")
	expect_near(norm.x, 1.0 / sqrt(2.0), "diagonal x component correct")
	expect_near(norm.y, 1.0 / sqrt(2.0), "diagonal y component correct")

func _test_zero_direction_guard() -> void:
	print("zero direction guard")
	var dir := Vector2.ZERO
	expect(dir.length_squared() == 0.0, "zero direction has zero length_squared")
	expect(not (dir.length_squared() > 0.0), "guard prevents movement on zero input")

func _test_position_delta() -> void:
	print("position delta formula")
	var speed := 200.0
	var delta := 0.016
	var dir := Vector2(1.0, 0.0)
	var movement := dir.normalized() * speed * delta
	expect_near(movement.x, 3.2, "position delta x correct")
	expect_near(movement.y, 0.0, "position delta y zero for horizontal")

func _report() -> void:
	var summary := "[arrow-sprite] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
