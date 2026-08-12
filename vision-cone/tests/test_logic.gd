extends Node

# Drives the real VisionCone from scripts/vision_cone.gd rather than a copy of
# its cone and occlusion maths.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_target_in_front_is_seen()
	_test_target_behind_is_not_seen()
	_test_cone_edges()
	_test_range_limit()
	_test_wall_blocks_line_of_sight()
	_test_wall_outside_the_line_does_not_block()
	_test_configurable_fov_and_range()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const ORIGIN := Vector2(100.0, 100.0)
const FACING_RIGHT := 0.0

func _make() -> VisionCone:
	return VisionCone.new(PI / 3.0, 180.0)   # 120° total FOV, 180px range

func _test_target_in_front_is_seen() -> void:
	print("target straight ahead")
	expect(_make().can_see(ORIGIN, FACING_RIGHT, ORIGIN + Vector2(100, 0)),
		"a target directly ahead and in range is visible")

func _test_target_behind_is_not_seen() -> void:
	print("target behind the observer")
	expect(not _make().can_see(ORIGIN, FACING_RIGHT, ORIGIN + Vector2(-100, 0)),
		"a target directly behind is outside the cone")

func _test_cone_edges() -> void:
	print("cone edges")
	var cone := _make()   # half_angle = 60°
	var inside := ORIGIN + Vector2.from_angle(deg_to_rad(55.0)) * 100.0
	var outside := ORIGIN + Vector2.from_angle(deg_to_rad(65.0)) * 100.0
	expect(cone.can_see(ORIGIN, FACING_RIGHT, inside), "55° off-axis is inside a 60° half-angle")
	expect(not cone.can_see(ORIGIN, FACING_RIGHT, outside), "65° off-axis is outside it")
	# The cone is symmetric, so the mirrored angles behave the same way.
	var mirrored := ORIGIN + Vector2.from_angle(deg_to_rad(-55.0)) * 100.0
	expect(cone.can_see(ORIGIN, FACING_RIGHT, mirrored), "the cone is symmetric about the facing")

func _test_range_limit() -> void:
	print("range limit")
	var cone := _make()   # 180px
	expect(cone.can_see(ORIGIN, FACING_RIGHT, ORIGIN + Vector2(179, 0)), "just inside range is visible")
	expect(not cone.can_see(ORIGIN, FACING_RIGHT, ORIGIN + Vector2(181, 0)), "just past range is not")

func _test_wall_blocks_line_of_sight() -> void:
	print("walls occlude")
	var cone := _make()
	var target := ORIGIN + Vector2(150, 0)
	var wall := Rect2(ORIGIN + Vector2(60, -40), Vector2(20, 80))
	expect(cone.can_see(ORIGIN, FACING_RIGHT, target), "clear line of sight without walls")
	expect(not cone.can_see(ORIGIN, FACING_RIGHT, target, [wall]), "a wall across the ray blocks sight")

func _test_wall_outside_the_line_does_not_block() -> void:
	print("walls off the ray")
	var cone := _make()
	var target := ORIGIN + Vector2(150, 0)
	var wall := Rect2(ORIGIN + Vector2(60, 60), Vector2(20, 80))   # well below the ray
	expect(cone.can_see(ORIGIN, FACING_RIGHT, target, [wall]),
		"a wall that does not cross the ray leaves sight clear")

func _test_configurable_fov_and_range() -> void:
	print("configurable fov and range")
	var narrow := VisionCone.new(deg_to_rad(10.0), 500.0)
	var target := ORIGIN + Vector2.from_angle(deg_to_rad(30.0)) * 200.0
	expect(not narrow.can_see(ORIGIN, FACING_RIGHT, target), "a narrow cone rejects a 30° target")
	var wide := VisionCone.new(deg_to_rad(80.0), 500.0)
	expect(wide.can_see(ORIGIN, FACING_RIGHT, target), "a wide cone accepts the same target")

func _report() -> void:
	var summary := "[vision-cone] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
