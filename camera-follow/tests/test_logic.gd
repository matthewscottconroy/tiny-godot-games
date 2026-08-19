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
	await _test_the_player_stays_down_and_the_camera_comes_along()
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

var _current: Node = null

## One world at a time.
##
## Each test used to add another copy of the scene and leave it there, so by the
## sixth there were six floors, six sets of walls and six players stacked at the
## same spawn — which is invisible while every test only reads configuration,
## and stops being invisible the moment one lets the physics run: the players
## depenetrate sideways and the one being watched is shoved off the level.
func _scene() -> Node:
	if _current != null and is_instance_valid(_current):
		remove_child(_current)      # out of the physics world now, not next frame
		_current.queue_free()
	_current = load("res://scenes/main.tscn").instantiate()
	add_child(_current)
	return _current

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

## The scene running, rather than the scene inspected.
##
## Everything above reads configuration, which is most of this demo's lesson but
## left its one script untested: every mutation to player.gd survived. The jump
## reads Input, which a headless test cannot press — but the other half of that
## condition is `is_on_floor()`, and it can be held from the outside. Loosen the
## `and` to an `or` and the player launches on every frame it is grounded.
func _test_the_player_stays_down_and_the_camera_comes_along() -> void:
	print("the scene running")
	var scene := _scene()
	var player: CharacterBody2D = scene.find_child("Player", true, false)
	var cam := _camera(scene)

	# The floor's top is at y=458 and the player is 40 tall, so it rests at 438.
	# Dropped from its spawn at 380 that is about twenty frames of falling.
	for _i in 40:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player lands on the floor")

	var resting := player.global_position.y
	var highest := resting
	for _i in 30:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with nothing pressed (rose %.1f px)" % (resting - highest))
	expect(absf(player.velocity.y) < 60.0,
		"never picking up upward speed (%.0f)" % player.velocity.y)

	# Parenting is the mechanism, so this is the assertion that it works rather
	# than merely being configured: move the player, and the camera is there.
	var moved := Vector2(700, resting)
	player.global_position = moved
	await get_tree().physics_frame
	expect(cam.global_position.distance_to(player.global_position) < 1.0,
		"the camera is wherever the player is (%s vs %s)"
		% [cam.global_position, player.global_position])

	# And the limits are the reason it does not show the void past the level's
	# edge — the screen centre stays a half-viewport inside them.
	var half := get_viewport().get_visible_rect().size.x * 0.5
	expect(cam.limit_left + half <= moved.x and moved.x <= cam.limit_right - half,
		"the player is somewhere the camera can actually centre on")

