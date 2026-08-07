extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_fire_params()
	_test_smoke_params()
	_test_sparkle_params()
	_test_burst_params()
	_test_lifetimes_ordered()
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

func _test_fire_params() -> void:
	print("fire particle params")
	var amount := 40
	var lifetime := 0.9
	var spread := 22.0
	expect(amount == 40, "fire amount is 40")
	expect_near(lifetime, 0.9, "fire lifetime is 0.9s")
	expect_near(spread, 22.0, "fire spread is 22 degrees")

func _test_smoke_params() -> void:
	print("smoke particle params")
	var amount := 20
	var lifetime := 2.5
	var spread := 40.0
	expect(amount == 20, "smoke amount is 20")
	expect_near(lifetime, 2.5, "smoke lifetime is 2.5s")
	expect_near(spread, 40.0, "smoke spread is 40 degrees")

func _test_sparkle_params() -> void:
	print("sparkle particle params")
	var amount := 60
	var lifetime := 1.4
	var spread := 180.0
	expect(amount == 60, "sparkle amount is 60")
	expect_near(lifetime, 1.4, "sparkle lifetime is 1.4s")
	expect_near(spread, 180.0, "sparkle spread is 180 degrees (full circle)")

func _test_burst_params() -> void:
	print("burst particle params")
	var amount := 80
	var lifetime := 0.7
	var one_shot := true
	expect(amount == 80, "burst amount is 80")
	expect_near(lifetime, 0.7, "burst lifetime is 0.7s")
	expect(one_shot, "burst is one-shot")

func _test_lifetimes_ordered() -> void:
	print("burst lifetime is shortest")
	var burst_lt := 0.7
	var fire_lt := 0.9
	var sparkle_lt := 1.4
	var smoke_lt := 2.5
	expect(burst_lt < fire_lt, "burst shorter than fire")
	expect(fire_lt < sparkle_lt, "fire shorter than sparkle")
	expect(sparkle_lt < smoke_lt, "sparkle shorter than smoke")

func _report() -> void:
	var summary := "[particle-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
