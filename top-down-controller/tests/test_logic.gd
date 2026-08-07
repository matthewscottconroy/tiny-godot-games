extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_diagonal_normalized()
	test_no_input_gives_zero()
	test_cardinal_speed()
	test_diagonal_speed()
	test_direction_tracked_when_idle()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[top-down-controller] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const SPEED := 200.0

func _compute_velocity(raw: Vector2) -> Vector2:
	var dir := raw.normalized() if raw.length() > 0.001 else Vector2.ZERO
	return dir * SPEED

func _update_last_dir(last: Vector2, dir: Vector2) -> Vector2:
	return dir if dir != Vector2.ZERO else last

func test_diagonal_normalized() -> void:
	var v := _compute_velocity(Vector2(1, 1))
	expect(absf(v.length() - SPEED) < 0.1, "diagonal input speed equals SPEED (not SPEED*sqrt2)")

func test_no_input_gives_zero() -> void:
	var v := _compute_velocity(Vector2.ZERO)
	expect(v == Vector2.ZERO, "zero input produces zero velocity")

func test_cardinal_speed() -> void:
	var v := _compute_velocity(Vector2(1, 0))
	expect(absf(v.length() - SPEED) < 0.01, "cardinal input speed equals SPEED")

func test_diagonal_speed() -> void:
	var v := _compute_velocity(Vector2(-1, -1))
	expect(absf(v.length() - SPEED) < 0.1, "diagonal negative input speed equals SPEED")

func test_direction_tracked_when_idle() -> void:
	var last := Vector2.RIGHT
	last = _update_last_dir(last, Vector2.ZERO)
	expect(last == Vector2.RIGHT, "last_dir preserved when input is zero")
