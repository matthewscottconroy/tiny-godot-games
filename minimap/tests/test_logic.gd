extends Node

# Drives the real minimap and camera from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_corners_of_the_world_map_to_the_corners_of_the_minimap()
	_test_the_middle_maps_to_the_middle()
	_test_the_mapping_keeps_its_proportions()
	_test_everything_in_the_world_lands_inside_the_minimap()
	_test_the_minimap_and_the_world_agree_on_the_terrain()
	_test_the_camera_follows_the_player()
	_test_the_camera_stops_at_the_edges_of_the_world()
	_test_the_minimap_is_fed_the_current_positions()
	_test_the_player_joins_the_player_group()
	_test_only_a_jump_key_press_latches_a_jump()
	_test_either_key_of_a_pair_moves_the_player()
	_test_a_latched_jump_is_spent_whether_or_not_it_fires()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[minimap] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _minimap(m: Node2D) -> Node2D:
	return m.get_node("CanvasLayer/Minimap")

func _test_the_corners_of_the_world_map_to_the_corners_of_the_minimap() -> void:
	print("the corners")
	var mini := _minimap(_make())
	var rect: Rect2 = mini.MAP_RECT
	expect(mini._world_to_map(Vector2.ZERO).is_equal_approx(rect.position),
		"the top-left of the world is the top-left of the minimap")
	expect(mini._world_to_map(Vector2(mini.WORLD_W, mini.WORLD_H)).is_equal_approx(rect.end),
		"and the bottom-right corner likewise")

func _test_the_middle_maps_to_the_middle() -> void:
	print("the middle")
	var mini := _minimap(_make())
	var rect: Rect2 = mini.MAP_RECT
	var centre: Vector2 = mini._world_to_map(Vector2(mini.WORLD_W, mini.WORLD_H) * 0.5)
	expect(centre.is_equal_approx(rect.position + rect.size * 0.5),
		"the centre of the world is the centre of the minimap")

func _test_the_mapping_keeps_its_proportions() -> void:
	print("proportions")
	var mini := _minimap(_make())
	# Two points a quarter of the world apart should be a quarter of the minimap
	# apart, or the minimap lies about where things are relative to each other.
	var a: Vector2 = mini._world_to_map(Vector2(mini.WORLD_W * 0.25, 0.0))
	var b: Vector2 = mini._world_to_map(Vector2(mini.WORLD_W * 0.5, 0.0))
	expect(is_equal_approx(b.x - a.x, mini.MAP_RECT.size.x * 0.25),
		"a quarter of the world is a quarter of the map")

func _test_everything_in_the_world_lands_inside_the_minimap() -> void:
	print("containment")
	var mini := _minimap(_make())
	var rect: Rect2 = mini.MAP_RECT.grow(0.001)
	var inside := true
	for i in 21:
		for j in 5:
			var world := Vector2(mini.WORLD_W * i / 20.0, mini.WORLD_H * j / 4.0)
			if not rect.has_point(mini._world_to_map(world)):
				inside = false
	expect(inside, "no part of the world is drawn outside the minimap frame")

func _test_the_minimap_and_the_world_agree_on_the_terrain() -> void:
	print("one world")
	var m := _make()
	var mini := _minimap(m)
	# The minimap keeps its own copy of the platform list. If the two drift
	# apart, the map shows terrain the player cannot stand on.
	expect(mini.PLATFORMS.size() == m.PLATFORMS.size(), "both lists hold the same number of platforms")
	var same := true
	for i in m.PLATFORMS.size():
		if mini.PLATFORMS[i] != m.PLATFORMS[i]:
			same = false
	expect(same, "and describe the same terrain")
	expect(is_equal_approx(mini.WORLD_W, m.WORLD_W), "with the same world width")

func _test_the_camera_follows_the_player() -> void:
	print("the camera")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var cam: Camera2D = m.get_node("Camera2D")
	player.global_position = Vector2(1000.0, 300.0)
	m._process(0.0)
	expect(is_equal_approx(cam.position.x, 1000.0), "the camera tracks the player across the world")
	expect(is_equal_approx(cam.position.y, 240.0), "and holds its height — this demo scrolls sideways")

func _test_the_camera_stops_at_the_edges_of_the_world() -> void:
	print("clamping")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var cam: Camera2D = m.get_node("Camera2D")

	player.global_position = Vector2(0.0, 300.0)
	m._process(0.0)
	expect(cam.position.x >= 320.0, "at the left edge the camera stops before showing past it")

	player.global_position = Vector2(m.WORLD_W, 300.0)
	m._process(0.0)
	expect(cam.position.x <= m.WORLD_W - 320.0, "and the same at the right edge")

func _test_the_minimap_is_fed_the_current_positions() -> void:
	print("feeding the minimap")
	var m := _make()
	var mini := _minimap(m)
	var player: CharacterBody2D = m.get_node("Player")
	player.global_position = Vector2(1234.0, 200.0)
	m._process(0.0)
	expect(mini.player_world_pos == player.global_position, "the minimap is told where the player is")
	expect(mini.cam_world_pos == (m.get_node("Camera2D") as Camera2D).position,
		"and where the camera is looking")

func _key(code: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	return e

func _test_the_player_joins_the_player_group() -> void:
	print("the player")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(player.is_in_group("player"), "the player registers itself for anything looking for it")
	expect(not player._jump_requested, "with no jump pending")

func _test_only_a_jump_key_press_latches_a_jump() -> void:
	print("the jump keys")
	var m := _make()
	for code in [KEY_SPACE, KEY_UP, KEY_W]:
		var player: CharacterBody2D = _make().get_node("Player")
		player._unhandled_key_input(_key(code))
		expect(player._jump_requested, "any of the three jump keys latches a jump")

	var other: CharacterBody2D = _make().get_node("Player")
	other._unhandled_key_input(_key(KEY_Q))
	expect(not other._jump_requested, "an unrelated key does not")

	var released: CharacterBody2D = _make().get_node("Player")
	released._unhandled_key_input(_key(KEY_SPACE, false))
	expect(not released._jump_requested, "nor does releasing a jump key")

	var repeated: CharacterBody2D = _make().get_node("Player")
	repeated._unhandled_key_input(_key(KEY_SPACE, true, true))
	expect(not repeated._jump_requested, "and holding one does not re-trigger through echoes")

func _test_a_latched_jump_is_spent_whether_or_not_it_fires() -> void:
	print("spending the jump")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	player._unhandled_key_input(_key(KEY_SPACE))
	player._physics_process(1.0 / 60.0)
	expect(not player._jump_requested, "the request is consumed by the frame that reads it")
	# In mid-air the jump is dropped rather than stored, so it cannot fire late
	# the moment the player lands.
	expect(player.velocity.y > 0.0, "and a jump pressed off the floor does not launch the player")

## Arrows and WASD are alternatives, not a chord.
##
## The two are joined with `or` for a reason: requiring both would mean holding
## Left *and* A to walk left, which is not a control scheme anyone would guess.
## The rule lives in its own function because the four flags it reads come from
## Input, which a headless test cannot press.
func _test_either_key_of_a_pair_moves_the_player() -> void:
	print("the two control schemes")
	var Player := load("res://scripts/player.gd")

	expect(Player.axis_from(true, false, false, false) < 0.0,
		"the left arrow alone walks left")
	expect(Player.axis_from(false, true, false, false) < 0.0,
		"and so does A alone")
	expect(Player.axis_from(false, false, true, false) > 0.0,
		"the right arrow alone walks right")
	expect(Player.axis_from(false, false, false, true) > 0.0,
		"and so does D alone")

	# Both keys of a pair is still one direction, not two.
	expect(Player.axis_from(true, true, false, false) == -1.0,
		"holding both left keys is still one step of left (%.1f)"
		% Player.axis_from(true, true, false, false))

	# Opposite directions cancel, whichever scheme each came from.
	expect(Player.axis_from(true, false, true, false) == 0.0,
		"left and right cancel")
	expect(Player.axis_from(false, true, false, true) == 0.0, "A and D cancel")
	expect(Player.axis_from(true, false, false, true) == 0.0,
		"and so do the two schemes mixed")

	# Nothing pressed is standing still.
	expect(Player.axis_from(false, false, false, false) == 0.0, "no keys, no movement")
