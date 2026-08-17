extends Node

# Drives the real rooms and camera from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_world_is_divided_into_rooms()
	_test_each_room_has_its_own_camera_position()
	_test_only_the_player_triggers_a_room()
	_test_entering_a_room_names_it()
	await _test_the_camera_travels_to_the_new_room()
	await _test_the_camera_eases_rather_than_cutting()
	_test_walking_on_through_hands_over_to_the_next_room()
	_test_the_player_jumps_only_from_the_floor()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[camera-rooms] %d/%d passed" % [_pass, _pass + _fail]
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

func _rooms(m: Node2D) -> Array[Area2D]:
	var found: Array[Area2D] = []
	for node in m.get_tree().get_nodes_in_group("room"):
		if node is Area2D and m.is_ancestor_of(node):
			found.append(node)
	return found

## Walk the player into a room and fire the overlap it would produce.
##
## The player is moved as well as the signal emitted: the rooms are real Area2Ds
## and the physics engine keeps emitting for whichever one the player is
## actually standing in, which would tween the camera straight back.
func _enter(m: Node2D, room: Area2D) -> void:
	(m.get_node("Player") as CharacterBody2D).global_position = room.global_position
	room.body_entered.emit(m.get_node("Player"))

func _test_the_world_is_divided_into_rooms() -> void:
	print("the rooms")
	var m := _make()
	var rooms := _rooms(m)
	expect(rooms.size() > 1, "the world holds several rooms (%d)" % rooms.size())
	for room in rooms:
		expect(room.room_name.length() > 0, "each room is named")

func _test_each_room_has_its_own_camera_position() -> void:
	print("camera targets")
	var m := _make()
	var targets := {}
	for room in _rooms(m):
		targets[room.cam_target] = true
	expect(targets.size() == _rooms(m).size(), "no two rooms frame the same view")

func _test_only_the_player_triggers_a_room() -> void:
	print("who counts")
	var m := _make()
	var room := _rooms(m)[0]
	var heard := {"count": 0}
	room.player_entered.connect(func(_n, _p): heard["count"] += 1)

	var passer_by := CharacterBody2D.new()
	add_child(passer_by)
	room.body_entered.emit(passer_by)
	expect(heard["count"] == 0, "something that is not the player does not move the camera")

	room.body_entered.emit(m.get_node("Player"))
	expect(heard["count"] == 1, "and the player does")

func _test_entering_a_room_names_it() -> void:
	print("the readout")
	var m := _make()
	var room := _rooms(m)[1]
	_enter(m, room)
	expect((m.get_node("HUD/RoomLabel") as Label).text.contains(room.room_name),
		"the label names the room the player walked into")

func _test_the_camera_travels_to_the_new_room() -> void:
	print("moving the camera")
	var m := _make()
	var camera: Camera2D = m.get_node("Camera2D")
	var room := _rooms(m)[1]
	_enter(m, room)
	# The tween runs for half a second of real time, so this waits frames until
	# it lands rather than guessing a count.
	for i in 200:
		await get_tree().process_frame
		if camera.position.is_equal_approx(room.cam_target):
			break
	expect(camera.position.is_equal_approx(room.cam_target),
		"the camera arrives at the new room's view")

func _test_the_camera_eases_rather_than_cutting() -> void:
	print("easing")
	var m := _make()
	var camera: Camera2D = m.get_node("Camera2D")
	var start: Vector2 = camera.position
	var room := _rooms(m)[2]
	_enter(m, room)
	await get_tree().process_frame
	await get_tree().process_frame
	# A cut would put the camera at the target on the first frame; the tween is
	# what makes the room change read as a move rather than a teleport.
	expect(camera.position != start, "the camera starts moving")
	expect(not camera.position.is_equal_approx(room.cam_target), "but does not arrive at once")

func _test_walking_on_through_hands_over_to_the_next_room() -> void:
	print("room to room")
	var m := _make()
	var label: Label = m.get_node("HUD/RoomLabel")
	var rooms := _rooms(m)
	_enter(m, rooms[0])
	expect(label.text.contains(rooms[0].room_name), "in the first room")
	_enter(m, rooms[1])
	expect(label.text.contains(rooms[1].room_name), "walking on names the next one")
	expect(not label.text.contains(rooms[0].room_name) or rooms[0].room_name == rooms[1].room_name,
		"and stops naming the one behind")

func _test_the_player_jumps_only_from_the_floor() -> void:
	print("the player")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(player.can_jump(true, true), "pressing jump on the floor jumps")
	expect(not player.can_jump(true, false), "pressing it in mid-air does not")
	expect(not player.can_jump(false, true), "and standing on the floor is not enough by itself")
	expect(player.is_in_group("player"), "the player is in the group the rooms look for")
