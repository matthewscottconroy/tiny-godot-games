extends Node

# Drives the real minimap from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_world_is_bigger_than_the_window()
	_test_the_minimap_shares_the_world()
	_test_the_minimap_camera_frames_the_whole_world()
	_test_the_display_shows_the_subviewport()
	_test_the_main_camera_follows_the_player()
	_test_the_player_stays_in_the_world()
	_test_the_dot_tracks_the_player_across_the_minimap()
	_test_the_dot_stays_on_the_minimap()
	_test_the_world_objects_are_scattered_and_repeatable()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[subviewport] %d/%d passed" % [_pass, _pass + _fail]
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

func _dot(m: Node2D) -> ColorRect:
	return m.get_node("HUD/PlayerDot")

func _dot_centre(m: Node2D) -> Vector2:
	var dot := _dot(m)
	return Vector2((dot.offset_left + dot.offset_right) * 0.5,
		(dot.offset_top + dot.offset_bottom) * 0.5)

func _test_the_world_is_bigger_than_the_window() -> void:
	print("the world")
	var m := _make()
	# A world that fits on screen needs no minimap, and the demo would show
	# the same picture twice.
	expect(m.WORLD_W > 640 and m.WORLD_H > 480, "the world is larger than the window")

func _test_the_minimap_shares_the_world() -> void:
	print("the shared world")
	var m := _make()
	var viewport: SubViewport = m.get_node("MinimapViewport")
	# Without sharing World2D the SubViewport renders an empty scene: the
	# minimap would be a blank rectangle.
	expect(viewport.world_2d == m.get_viewport().world_2d,
		"the minimap viewport draws the same world as the main one")

func _test_the_minimap_camera_frames_the_whole_world() -> void:
	print("the minimap camera")
	var m := _make()
	var camera: Camera2D = m.get_node("MinimapViewport/MinimapCamera")
	expect(camera.zoom.x < 1.0, "the minimap camera is zoomed out")
	expect(is_equal_approx(camera.zoom.x, camera.zoom.y), "evenly on both axes, so nothing is squashed")
	expect(camera.position.is_equal_approx(Vector2(m.WORLD_W / 2.0, m.WORLD_H / 2.0)),
		"and centred on the world")

	# Zoomed far enough out that the whole world fits in the little viewport.
	expect(m.WORLD_W * camera.zoom.x <= m.MINIMAP_W + 1.0, "the world's width fits the minimap")
	expect(m.WORLD_H * camera.zoom.y <= m.MINIMAP_H + 1.0, "and its height")

func _test_the_display_shows_the_subviewport() -> void:
	print("the display")
	var m := _make()
	var display: TextureRect = m.get_node("HUD/MinimapDisplay")
	var viewport: SubViewport = m.get_node("MinimapViewport")
	expect(display.texture == viewport.get_texture(),
		"the HUD shows the minimap viewport's own output")

func _test_the_main_camera_follows_the_player() -> void:
	print("the main camera")
	var m := _make()
	var camera: Camera2D = m.get_node("MainCamera")
	m.tick(1.0, Vector2.RIGHT)
	expect(camera.position.is_equal_approx(m._player_pos), "the main camera sits on the player")

func _test_the_player_stays_in_the_world() -> void:
	print("the edges")
	var m := _make()
	for i in 200:
		m.tick(0.1, Vector2(1.0, 1.0))
	expect(m._player_pos.x < m.WORLD_W, "walking right stops at the edge of the world")
	expect(m._player_pos.y < m.WORLD_H, "and walking down at the bottom of it")
	for i in 400:
		m.tick(0.1, Vector2(-1.0, -1.0))
	expect(m._player_pos.x > 0.0, "and the other two edges hold as well")
	expect(m._player_pos.y > 0.0, "on both axes")

func _test_the_dot_tracks_the_player_across_the_minimap() -> void:
	print("the dot")
	var m := _make()
	m._player_pos = Vector2(m.WORLD_W * 0.25, m.WORLD_H * 0.25)
	m.tick(0.0, Vector2.ZERO)
	var near_corner: Vector2 = _dot_centre(m)

	m._player_pos = Vector2(m.WORLD_W * 0.75, m.WORLD_H * 0.75)
	m.tick(0.0, Vector2.ZERO)
	var far_corner: Vector2 = _dot_centre(m)

	expect(far_corner.x > near_corner.x, "walking right moves the dot right on the minimap")
	expect(far_corner.y > near_corner.y, "and walking down moves it down")
	expect(_dot(m).visible, "with the dot visible")

func _test_the_dot_stays_on_the_minimap() -> void:
	print("the dot's bounds")
	var m := _make()
	var origin := Vector2(470.0, 360.0)
	var frame := Rect2(origin, Vector2(m.MINIMAP_W, m.MINIMAP_H)).grow(4.0)
	begin_quiet()
	for corner in [Vector2(16.0, 16.0), Vector2(m.WORLD_W - 16.0, 16.0),
			Vector2(16.0, m.WORLD_H - 16.0), Vector2(m.WORLD_W - 16.0, m.WORLD_H - 16.0)]:
		m._player_pos = corner
		m.tick(0.0, Vector2.ZERO)
		expect_quiet(frame.has_point(_dot_centre(m)),
			"the player at %s puts the dot at %s, off the minimap" % [corner, _dot_centre(m)])
	expect(_quiet_failures == 0, "the dot stays inside the minimap at every corner of the world")

func _test_the_world_objects_are_scattered_and_repeatable() -> void:
	print("the scenery")
	var m := _make()
	expect(m._objects.size() > 10, "the world is furnished")
	begin_quiet()
	for object in m._objects:
		var pos: Vector2 = object["pos"]
		expect_quiet(pos.x >= 0.0 and pos.x <= m.WORLD_W and pos.y >= 0.0 and pos.y <= m.WORLD_H,
			"an object sits outside the world at %s" % pos)
	expect(_quiet_failures == 0, "every object is inside the world")

	# A fixed seed, so the demo looks the same every run and a screenshot of it
	# means something.
	var again := _make()
	expect(again._objects[0]["pos"] == m._objects[0]["pos"], "the layout is the same every run")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
