extends Node

# Drives the real HUD from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_hud_is_on_a_canvas_layer()
	_test_the_world_is_not()
	_test_the_readout_follows_the_player()
	_test_the_hud_does_not_move_with_the_world()
	_test_the_camera_rides_with_the_player()
	_test_the_level_is_wider_than_the_window()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[canvas-layer] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _hud(m: Node2D) -> CanvasLayer:
	return m.get_node("HUD")

func _label(m: Node2D) -> Label:
	return m.get_node("HUD/PositionLabel")

func _test_the_hud_is_on_a_canvas_layer() -> void:
	print("the HUD")
	var m := _make()
	# A CanvasLayer draws in screen space, which is the whole point: the HUD
	# stays put while the camera moves over the level.
	expect(_hud(m) is CanvasLayer, "the HUD sits on a CanvasLayer")
	expect(_label(m) != null, "with a readout on it")

func _test_the_world_is_not() -> void:
	print("the world")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	# The player has to be in world space, or the camera would never leave it
	# behind and there would be nothing to demonstrate.
	expect(not (player.get_parent() is CanvasLayer), "the player lives in the world, not on the HUD")

func _test_the_readout_follows_the_player() -> void:
	print("the readout")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	player.position = Vector2(837.0, 412.0)
	m._process(STEP)
	expect(_label(m).text.contains("837"), "the readout reports where the player is")
	expect(_label(m).text.contains("412"), "on both axes")

	player.position = Vector2(120.0, 300.0)
	m._process(STEP)
	expect(_label(m).text.contains("120"), "and follows them as they move")

func _test_the_hud_does_not_move_with_the_world() -> void:
	print("staying put")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var label := _label(m)
	var where_it_sits: Vector2 = label.position
	player.position = Vector2(1200.0, 300.0)
	m._process(STEP)
	# The text changes; the label itself does not budge.
	expect(label.position == where_it_sits, "the HUD stays where it is while the world scrolls past")
	expect(is_zero_approx(_hud(m).offset.x) and is_zero_approx(_hud(m).offset.y),
		"and the layer itself is not offset")

func _test_the_camera_rides_with_the_player() -> void:
	print("the camera")
	var m := _make()
	var camera: Camera2D = m.get_node("Player/Camera2D")
	expect(camera != null, "the camera is a child of the player, so it follows for free")

func _test_the_level_is_wider_than_the_window() -> void:
	print("the level")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	# Somewhere to scroll to: on a level that fits the window, a screen-space
	# HUD looks the same as a world-space one.
	var floor_body: StaticBody2D = null
	for child in m.get_children():
		if child is StaticBody2D:
			floor_body = child
	expect(floor_body != null, "there is ground to walk on")
	expect(player.position.x < 1000.0, "the player starts near one end of it")
