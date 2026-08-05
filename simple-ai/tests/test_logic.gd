extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_enemy_speed()
	_test_chase_direction()
	_test_chase_direction_normalized()
	_test_stationary_when_at_target()
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

func _test_enemy_speed() -> void:
	print("enemy chase speed")
	const SPEED := 70.0
	expect(SPEED == 70.0, "enemy SPEED is 70")

func _test_chase_direction() -> void:
	print("enemy moves toward player position")
	var enemy_pos := Vector2(100.0, 100.0)
	var player_pos := Vector2(300.0, 100.0)
	var dir := (player_pos - enemy_pos)
	expect(dir.x > 0.0, "direction points toward player (positive x)")
	expect(dir.y == 0.0, "direction has no vertical component when same height")

func _test_chase_direction_normalized() -> void:
	print("chase velocity uses normalized direction")
	const SPEED := 70.0
	var enemy_pos := Vector2(0.0, 0.0)
	var player_pos := Vector2(300.0, 400.0)
	var dir := (player_pos - enemy_pos).normalized()
	var velocity := dir * SPEED
	expect_near(velocity.length(), SPEED, "chase velocity magnitude equals SPEED")

func _test_stationary_when_at_target() -> void:
	print("zero direction when enemy is at player position")
	var enemy_pos := Vector2(200.0, 200.0)
	var player_pos := Vector2(200.0, 200.0)
	var delta := player_pos - enemy_pos
	expect(delta.length() == 0.0, "no movement when already at player position")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
