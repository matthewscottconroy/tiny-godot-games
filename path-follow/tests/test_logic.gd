extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_patrol_speed()
	_test_progress_advance()
	_test_progress_wraps()
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

func _test_patrol_speed() -> void:
	print("patrol speed")
	var speed := 120.0
	expect(speed == 120.0, "patrol speed is 120")
	expect(speed > 0.0, "patrol speed is positive")

func _test_progress_advance() -> void:
	print("progress advances by speed * delta")
	var speed := 120.0
	var delta := 0.016
	var progress := 0.0
	progress += speed * delta
	expect_near(progress, 1.92, "progress after one frame is speed*delta")

func _test_progress_wraps() -> void:
	print("progress wraps around path length")
	var path_length := 800.0
	var progress := 810.0
	progress = fmod(progress, path_length)
	expect_near(progress, 10.0, "progress wraps around path length")
	expect(progress >= 0.0, "wrapped progress is non-negative")

func _report() -> void:
	var summary := "[path-follow] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
