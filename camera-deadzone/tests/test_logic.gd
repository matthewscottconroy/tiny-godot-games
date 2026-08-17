extends Node

# Drives the real camera logic from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_centre_is_inside_the_zone()
	_test_edges_are_inside()
	_test_just_past_the_edge_is_outside()
	_test_camera_holds_still_inside_the_zone()
	_test_camera_follows_once_outside()
	_test_camera_stops_at_the_zone_edge()
	_test_axes_are_independent()
	_test_symmetric_in_all_four_directions()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[camera-deadzone] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const CAM := Vector2(500, 300)
var _script: GDScript = load("res://scripts/main.gd")

func _main() -> Node2D:
	var m := Node2D.new()
	m.set_script(_script)
	# Not added to the tree: _process and @onready would need the real scene,
	# and the two functions under test are pure.
	return m

func _test_centre_is_inside_the_zone() -> void:
	print("inside the zone")
	var m := _main()
	expect(m.in_dead_zone(CAM, CAM), "the player standing on the camera is inside")

func _test_edges_are_inside() -> void:
	print("the edges")
	var m := _main()
	expect(m.in_dead_zone(CAM, CAM + Vector2(m.DEAD_W, 0)), "exactly at the horizontal edge counts as inside")
	expect(m.in_dead_zone(CAM, CAM + Vector2(0, m.DEAD_H)), "and at the vertical edge")

func _test_just_past_the_edge_is_outside() -> void:
	print("past the edge")
	var m := _main()
	expect(not m.in_dead_zone(CAM, CAM + Vector2(m.DEAD_W + 1.0, 0)), "one pixel past is outside")

func _test_camera_holds_still_inside_the_zone() -> void:
	print("stillness")
	var m := _main()
	# The entire point of a dead zone: small movements move nothing.
	for offset in [Vector2.ZERO, Vector2(30, 0), Vector2(0, -20), Vector2(-70, 30)]:
		expect(m.camera_target(CAM, CAM + offset) == CAM,
			"a player %s from centre leaves the camera where it is" % offset)

func _test_camera_follows_once_outside() -> void:
	print("following")
	var m := _main()
	var target: Vector2 = m.camera_target(CAM, CAM + Vector2(m.DEAD_W + 100.0, 0))
	expect(target.x > CAM.x, "the camera target moves toward a player past the edge")

func _test_camera_stops_at_the_zone_edge() -> void:
	print("the catch-up distance")
	var m := _main()
	var player := CAM + Vector2(m.DEAD_W + 100.0, 0)
	var target: Vector2 = m.camera_target(CAM, player)
	# The target trails the player by exactly the zone width, so the camera
	# settles with the player on the edge rather than centred.
	expect(is_equal_approx(player.x - target.x, m.DEAD_W),
		"the target sits exactly DEAD_W behind the player")

func _test_axes_are_independent() -> void:
	print("independent axes")
	var m := _main()
	# Far out horizontally, still inside vertically: only x should move.
	var player := CAM + Vector2(m.DEAD_W + 50.0, 10.0)
	var target: Vector2 = m.camera_target(CAM, player)
	expect(target.x != CAM.x, "the horizontal axis follows")
	expect(is_equal_approx(target.y, CAM.y), "while the vertical one stays put")

func _test_symmetric_in_all_four_directions() -> void:
	print("symmetry")
	var m := _main()
	var right: Vector2 = m.camera_target(CAM, CAM + Vector2(m.DEAD_W + 60.0, 0))
	var left: Vector2 = m.camera_target(CAM, CAM - Vector2(m.DEAD_W + 60.0, 0))
	expect(is_equal_approx(right.x - CAM.x, CAM.x - left.x), "left and right behave alike")
	var down: Vector2 = m.camera_target(CAM, CAM + Vector2(0, m.DEAD_H + 60.0))
	var up: Vector2 = m.camera_target(CAM, CAM - Vector2(0, m.DEAD_H + 60.0))
	expect(is_equal_approx(down.y - CAM.y, CAM.y - up.y), "up and down behave alike")
