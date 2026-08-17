extends Node

# Drives the real room from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# This demo's lesson is scene setup: a room larger than the window, walls that
# hold the player in, and a camera limited to the room. So the suite asserts
# that setup and then walks the player into things to check it holds.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_room_is_bigger_than_the_window()
	_test_the_camera_is_limited_to_the_room()
	_test_the_camera_rides_with_the_player()
	_test_the_room_is_walled_on_all_four_sides()
	_test_the_room_has_obstacles_in_it()
	_test_the_player_starts_inside()
	await _test_the_walls_stop_the_player()
	await _test_an_obstacle_stops_the_player()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[tilemap-room] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _player(m: Node2D) -> CharacterBody2D:
	return m.get_node("Player")

func _camera(m: Node2D) -> Camera2D:
	return m.get_node("Player/Camera2D")

func _static_bodies(m: Node2D) -> Array[StaticBody2D]:
	var bodies: Array[StaticBody2D] = []
	for child in m.get_children():
		if child is StaticBody2D:
			bodies.append(child)
	return bodies

## Push the player in a direction for a while and report where they end up.
func _walk(m: Node2D, direction: Vector2, frames: int) -> Vector2:
	var player := _player(m)
	for i in frames:
		player.velocity = direction * player.SPEED
		player.move_and_slide()
		await get_tree().physics_frame
	return player.global_position

func _test_the_room_is_bigger_than_the_window() -> void:
	print("the room")
	var m := _make()
	# If the room fitted on screen there would be nothing to scroll, and the
	# camera limits would never come into play.
	expect(m.ROOM_W > 640 and m.ROOM_H > 480, "the room is larger than the window")

func _test_the_camera_is_limited_to_the_room() -> void:
	print("camera limits")
	var m := _make()
	var cam := _camera(m)
	expect(cam.limit_left == 0 and cam.limit_top == 0, "the camera stops at the top-left of the room")
	expect(cam.limit_right == m.ROOM_W, "and at its right edge")
	expect(cam.limit_bottom == m.ROOM_H, "and its bottom — no black space beyond the room")
	expect(cam.limit_right > cam.limit_left and cam.limit_bottom > cam.limit_top,
		"with the limits the right way round")

func _test_the_camera_rides_with_the_player() -> void:
	print("the camera")
	var m := _make()
	expect(_camera(m).get_parent() == _player(m),
		"the camera is a child of the player, so following costs no code at all")

func _test_the_room_is_walled_on_all_four_sides() -> void:
	print("the walls")
	var m := _make()
	for name in ["WallTop", "WallBottom", "WallLeft", "WallRight"]:
		expect(m.has_node(name), "the room has a %s" % name)

func _test_the_room_has_obstacles_in_it() -> void:
	print("obstacles")
	var m := _make()
	var bodies := _static_bodies(m)
	expect(bodies.size() > 4, "there is more in the room than its four walls (%d bodies)" % bodies.size())

func _test_the_player_starts_inside() -> void:
	print("the player")
	var m := _make()
	var pos: Vector2 = _player(m).global_position
	expect(pos.x > 0.0 and pos.x < m.ROOM_W, "the player starts inside the room horizontally")
	expect(pos.y > 0.0 and pos.y < m.ROOM_H, "and vertically")

func _test_the_walls_stop_the_player() -> void:
	print("hitting a wall")
	var m := _make()
	_player(m).global_position = Vector2(100.0, 480.0)
	var ended_at: Vector2 = await _walk(m, Vector2.LEFT, 40)
	expect(ended_at.x > 0.0, "walking into the left wall does not leave the room")
	expect(ended_at.x < 100.0, "though the player does travel until they reach it")

func _test_an_obstacle_stops_the_player() -> void:
	print("hitting a box")
	var m := _make()
	var box: StaticBody2D = m.get_node("Box1")
	# Lined up to the left of the box, walking straight into it.
	_player(m).global_position = box.global_position - Vector2(200.0, 0.0)
	var ended_at: Vector2 = await _walk(m, Vector2.RIGHT, 40)
	expect(ended_at.x < box.global_position.x, "the player is stopped short of the obstacle")
	expect(ended_at.x > box.global_position.x - 200.0, "having walked up to it")
