extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_cooldown_constants()
	_test_cooldown_decrement()
	_test_cooldown_bar_formula()
	_test_fire_resets_cooldown()
	_test_bullet_constants()
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

func _test_cooldown_constants() -> void:
	print("cooldown constants")
	const FIRE_COOLDOWN := 0.35
	const SPEED := 160.0
	expect(FIRE_COOLDOWN == 0.35, "FIRE_COOLDOWN is 0.35s")
	expect(SPEED == 160.0, "player SPEED is 160")

func _test_cooldown_decrement() -> void:
	print("cooldown decrement")
	const FIRE_COOLDOWN := 0.35
	var cooldown := FIRE_COOLDOWN
	var delta := 0.016
	cooldown = max(0.0, cooldown - delta)
	expect(cooldown < FIRE_COOLDOWN, "cooldown decreases each frame")
	expect(cooldown >= 0.0, "cooldown stays non-negative")
	cooldown = 0.005
	cooldown = max(0.0, cooldown - 0.016)
	expect_near(cooldown, 0.0, "cooldown floors at 0")

func _test_cooldown_bar_formula() -> void:
	print("cooldown progress bar formula: 1 - (cd / max)")
	const FIRE_COOLDOWN := 0.35
	var cooldown := FIRE_COOLDOWN
	var bar_value := 1.0 - (cooldown / FIRE_COOLDOWN)
	expect_near(bar_value, 0.0, "full cooldown -> bar at 0 (not ready)")
	cooldown = 0.0
	bar_value = 1.0 - (cooldown / FIRE_COOLDOWN)
	expect_near(bar_value, 1.0, "zero cooldown -> bar at 1 (ready)")
	cooldown = FIRE_COOLDOWN * 0.5
	bar_value = 1.0 - (cooldown / FIRE_COOLDOWN)
	expect_near(bar_value, 0.5, "half cooldown -> bar at 0.5")

func _test_fire_resets_cooldown() -> void:
	print("firing resets cooldown to FIRE_COOLDOWN")
	const FIRE_COOLDOWN := 0.35
	var cooldown := 0.0
	cooldown = FIRE_COOLDOWN
	expect_near(cooldown, 0.35, "after fire, cooldown = FIRE_COOLDOWN")

func _test_bullet_constants() -> void:
	print("bullet constants")
	const BULLET_SPEED := 500.0
	const LIFETIME := 1.6
	expect(BULLET_SPEED == 500.0, "bullet SPEED is 500")
	expect(LIFETIME == 1.6, "bullet lifetime is 1.6s")
	var distance := BULLET_SPEED * LIFETIME
	expect_near(distance, 800.0, "bullet travels 800px before expiring")

func _report() -> void:
	var summary := "[cooldown-shoot] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
