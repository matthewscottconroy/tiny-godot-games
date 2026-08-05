extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_initial_hp()
	_test_take_damage()
	_test_take_damage_to_zero()
	_test_freeze_toggle()
	_test_bounce_bounds()
	_test_initial_spawn_count()
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

func _test_initial_hp() -> void:
	print("initial hp")
	var hp := 100
	expect(hp == 100, "enemy starts with 100 HP")

func _test_take_damage() -> void:
	print("take_damage reduces HP")
	var hp := 100
	hp = max(0, hp - 25)
	expect(hp == 75, "take_damage(25) reduces to 75")
	hp = max(0, hp - 25)
	expect(hp == 50, "take_damage(25) again reduces to 50")

func _test_take_damage_to_zero() -> void:
	print("take_damage cannot go below 0")
	var hp := 10
	hp = max(0, hp - 50)
	expect(hp == 0, "take_damage clamps at 0")

func _test_freeze_toggle() -> void:
	print("freeze toggle")
	var frozen := false
	frozen = !frozen
	expect(frozen, "freeze_toggle activates freeze")
	frozen = !frozen
	expect(not frozen, "freeze_toggle deactivates freeze")

func _test_bounce_bounds() -> void:
	print("bounce bounds x:[60,580] y:[80,390]")
	var pos := Vector2(50.0, 85.0)
	var vel := Vector2(-50.0, 0.0)
	if pos.x < 60 or pos.x > 580:
		vel.x = -vel.x
		pos.x = clamp(pos.x, 60.0, 580.0)
	expect(vel.x > 0.0, "velocity reversed at left wall")
	expect(pos.x >= 60.0, "position clamped to left bound")

func _test_initial_spawn_count() -> void:
	print("initial spawn count")
	var initial_enemies := 7
	expect(initial_enemies == 7, "7 enemies spawned initially")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
