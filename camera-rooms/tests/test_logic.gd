extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_room_signal_emission()
	_test_cam_target_per_room()
	_test_non_player_body_ignored()
	_test_tween_target_position()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx_v2(a: Vector2, b: Vector2, label: String, tol: float = 0.01) -> void:
	expect(a.distance_to(b) < tol, label)

# --- Minimal room + camera simulation ---

class FakeBody:
	var _groups: Array[String] = []
	func add_group(g: String) -> void:
		_groups.append(g)
	func is_in_group(g: String) -> bool:
		return g in _groups

class FakeRoom:
	var room_name: String = "Room"
	var cam_target: Vector2 = Vector2.ZERO
	var last_emitted_name: String = ""
	var last_emitted_pos: Vector2 = Vector2(-9999, -9999)
	var signal_count: int = 0

	func _on_body(body: FakeBody) -> void:
		if body.is_in_group("player"):
			last_emitted_name = room_name
			last_emitted_pos  = cam_target
			signal_count     += 1

class FakeCam:
	var position: Vector2 = Vector2.ZERO
	var tween_target: Vector2 = Vector2.ZERO

	func tween_to(target: Vector2) -> void:
		tween_target = target
		position     = target  # instant in tests

# --- Tests ---

func _test_room_signal_emission() -> void:
	print("room emits signal when player enters")
	var room := FakeRoom.new()
	room.room_name  = "Room1"
	room.cam_target = Vector2(320, 240)

	var player := FakeBody.new()
	player.add_group("player")

	room._on_body(player)
	expect(room.signal_count == 1, "signal emitted exactly once")
	expect(room.last_emitted_name == "Room1", "emitted room_name is correct")
	expect_approx_v2(room.last_emitted_pos, Vector2(320, 240), "emitted cam_pos is correct")

func _test_cam_target_per_room() -> void:
	print("each room carries its own cam_target")
	var rooms := [
		{"name": "Room1", "target": Vector2(320,  240)},
		{"name": "Room2", "target": Vector2(960,  240)},
		{"name": "Room3", "target": Vector2(1600, 240)},
	]

	for r in rooms:
		var room := FakeRoom.new()
		room.room_name  = r["name"]
		room.cam_target = r["target"]

		var player := FakeBody.new()
		player.add_group("player")
		room._on_body(player)

		expect(room.last_emitted_name == r["name"],
			"%s emits its own name" % r["name"])
		expect_approx_v2(room.last_emitted_pos, r["target"],
			"%s emits correct cam_target" % r["name"])

func _test_non_player_body_ignored() -> void:
	print("non-player bodies do not trigger room signal")
	var room := FakeRoom.new()
	room.room_name  = "Room1"
	room.cam_target = Vector2(320, 240)

	var enemy := FakeBody.new()
	enemy.add_group("enemy")

	room._on_body(enemy)
	expect(room.signal_count == 0, "signal NOT emitted for non-player body")

func _test_tween_target_position() -> void:
	print("camera tween targets the room cam_target")
	var cam  := FakeCam.new()
	cam.position = Vector2(320, 240)

	# Simulate entering Room2
	var target := Vector2(960, 240)
	cam.tween_to(target)
	expect_approx_v2(cam.tween_target, target, "tween target set to Room2 cam_target")

	# Simulate entering Room3
	var target3 := Vector2(1600, 240)
	cam.tween_to(target3)
	expect_approx_v2(cam.tween_target, target3, "tween target updated to Room3 cam_target")

func _report() -> void:
	var summary := "[camera-rooms] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
