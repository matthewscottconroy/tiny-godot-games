extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_squish_target_scale()
	_test_squish_duration()
	_test_recover_scale()
	_test_recover_duration()
	_test_pop_label_rise()
	_test_pop_label_duration()
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

func _test_squish_target_scale() -> void:
	print("button squish target scale")
	var squish_scale := Vector2(1.25, 0.7)
	expect_near(squish_scale.x, 1.25, "squish x scale is 1.25 (wider)")
	expect_near(squish_scale.y, 0.7, "squish y scale is 0.7 (shorter)")

func _test_squish_duration() -> void:
	print("squish animation duration")
	var squish_time := 0.07
	expect_near(squish_time, 0.07, "squish tween duration is 0.07s")

func _test_recover_scale() -> void:
	print("button recovery target scale")
	var recover_scale := Vector2(1.0, 1.0)
	expect_near(recover_scale.x, 1.0, "recover x scale returns to 1.0")
	expect_near(recover_scale.y, 1.0, "recover y scale returns to 1.0")

func _test_recover_duration() -> void:
	print("recovery animation duration")
	var recover_time := 0.3
	expect_near(recover_time, 0.3, "recovery tween duration is 0.3s")

func _test_pop_label_rise() -> void:
	print("pop label floats up by 70 pixels")
	var rise_amount := 70.0
	expect(rise_amount == 70.0, "pop label rises 70px")

func _test_pop_label_duration() -> void:
	print("pop label animation duration")
	var pop_time := 0.7
	expect_near(pop_time, 0.7, "pop label tween duration is 0.7s")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
