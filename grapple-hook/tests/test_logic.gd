extends Node

const HOOK_SPEED := 550.0
const EXPLOSION_RADIUS := 180.0

var _pass := 0
var _fail := 0

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: ", label)
	else:
		_fail += 1
		print("  FAIL: ", label)

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])

func _ready() -> void:
	print("=== Grapple Hook Tests ===")
	_test_hook_direction()
	_test_pendulum_constraint()
	_test_platform_hit()
	_test_rope_length()
	_report()

func _test_hook_direction() -> void:
	print("_test_hook_direction")
	var from := Vector2(0.0, 0.0)
	var target := Vector2(640.0, 480.0)
	var direction := from.direction_to(target)
	var expected := Vector2(1.0, 1.0).normalized()
	expect(direction.is_equal_approx(expected), "shooting toward (640,480) from (0,0) gives normalized (1,1) direction")

func _test_pendulum_constraint() -> void:
	print("_test_pendulum_constraint")
	var hook_pos := Vector2(200.0, 100.0)
	var rope_len := 80.0

	# Player is too far from anchor (120 > 80)
	var player_pos := Vector2(200.0, 220.0)
	var rope := player_pos - hook_pos
	if rope.length() > rope_len:
		var rope_dir := rope.normalized()
		player_pos = hook_pos + rope_dir * rope_len

	var new_dist := player_pos.distance_to(hook_pos)
	expect(is_equal_approx(new_dist, rope_len), "pendulum constraint pulls player back to rope_len distance")
	expect(new_dist <= rope_len + 0.001, "player is not further than rope_len after constraint")

func _test_platform_hit() -> void:
	print("_test_platform_hit")
	var platform := Rect2(100.0, 320.0, 160.0, 20.0)

	# Hook tip inside platform
	var hit_pos := Vector2(150.0, 330.0)
	expect(platform.has_point(hit_pos), "hook tip inside platform rect returns true")

	# Hook tip outside platform
	var miss_pos := Vector2(50.0, 300.0)
	expect(not platform.has_point(miss_pos), "hook tip outside platform rect returns false")

func _test_rope_length() -> void:
	print("_test_rope_length")
	var player_pos := Vector2(300.0, 400.0)
	var anchor_pos := Vector2(200.0, 200.0)

	# Simulate attaching: rope_len = distance(player, anchor)
	var rope_len := player_pos.distance_to(anchor_pos)
	var expected := sqrt(pow(300.0 - 200.0, 2.0) + pow(400.0 - 200.0, 2.0))

	expect(is_equal_approx(rope_len, expected), "rope_len equals distance from player to anchor on attach")
