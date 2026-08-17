extends Node

# This demo's lesson is scene configuration, not script logic: a Camera2D
# parented to the player, with smoothing and limits. So the suite drives the
# real scene and asserts that configuration, rather than recomputing a
# smoothing formula the demo never runs. See docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_camera_is_parented_to_the_player()
	_test_smoothing_is_enabled()
	_test_limits_are_set_and_ordered()
	_test_limits_are_larger_than_the_viewport()
	_test_camera_is_current()
	_test_player_gravity_and_jump_constants()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[camera-follow] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _scene() -> Node:
	var s: Node = load("res://scenes/main.tscn").instantiate()
	add_child(s)
	return s

func _camera(scene: Node) -> Camera2D:
	return scene.find_child("Camera2D", true, false) as Camera2D

func _test_camera_is_parented_to_the_player() -> void:
	print("parenting")
	var scene := _scene()
	var cam := _camera(scene)
	expect(cam != null, "the scene has a Camera2D")
	# Parenting is what makes it follow: no per-frame code is involved at all.
	expect(cam.get_parent().name == "Player",
		"the camera is a child of the player, which is what makes it follow")

func _test_smoothing_is_enabled() -> void:
	print("smoothing")
	var cam := _camera(_scene())
	expect(cam.position_smoothing_enabled,
		"smoothing is on — without it the camera snaps and the motion reads as jitter")
	expect(cam.position_smoothing_speed > 0.0, "and its speed is positive")

func _test_limits_are_set_and_ordered() -> void:
	print("limits")
	var cam := _camera(_scene())
	expect(cam.limit_right > cam.limit_left, "the horizontal limits are the right way round")
	expect(cam.limit_bottom > cam.limit_top, "so are the vertical ones")

func _test_limits_are_larger_than_the_viewport() -> void:
	print("limit extent")
	var cam := _camera(_scene())
	var width := cam.limit_right - cam.limit_left
	# Limits smaller than the view would clamp the camera inside the level and
	# show the void beyond its edge.
	expect(width >= 640, "the bounded area is at least a viewport wide")

func _test_camera_is_current() -> void:
	print("active camera")
	var cam := _camera(_scene())
	expect(cam.enabled, "the camera is enabled, so it is the one being rendered through")

func _test_player_gravity_and_jump_constants() -> void:
	print("player tuning")
	var player: CharacterBody2D = _scene().find_child("Player", true, false)
	expect(player != null, "the scene has a player")
	expect(player.GRAVITY > 0.0, "gravity pulls down")
	expect(player.JUMP_VEL < 0.0, "and the jump impulse is upward — Y is down in 2D")
	expect(player.SPEED > 0.0, "the player moves")
