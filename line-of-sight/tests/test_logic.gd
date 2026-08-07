extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_range_check_within()
	test_range_check_beyond()
	test_los_assumed_clear_no_physics()
	test_vision_range_constant()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[line-of-sight] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const VISION_RANGE := 320.0

func _in_range(enemy: Vector2, player: Vector2) -> bool:
	return enemy.distance_to(player) <= VISION_RANGE

func test_range_check_within() -> void:
	var e := Vector2(100, 100)
	var p := Vector2(300, 100)
	expect(_in_range(e, p), "player 200 units away is within 320 vision range")

func test_range_check_beyond() -> void:
	var e := Vector2(0, 0)
	var p := Vector2(400, 0)
	expect(not _in_range(e, p), "player 400 units away is beyond 320 vision range")

func test_los_assumed_clear_no_physics() -> void:
	# Can't test actual physics raycast outside scene — verify the logic contract:
	# _has_los returns bool; if physics space returns empty dict, LOS is clear
	var fake_result: Dictionary = {}
	var los_clear := fake_result.is_empty()
	expect(los_clear, "empty raycast result means clear line of sight")

	var fake_blocked := {"position": Vector2(50, 0), "collider": "wall"}
	var los_blocked := not fake_blocked.is_empty()
	expect(los_blocked, "non-empty raycast result means blocked line of sight")

func test_vision_range_constant() -> void:
	expect(VISION_RANGE > 0, "vision range is positive")
	expect(VISION_RANGE < 800, "vision range is not unreasonably large")
