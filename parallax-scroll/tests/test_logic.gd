extends Node

# Drives the real layers from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# Parallax is scene configuration: the depth is in each layer's motion_scale.
# So the suite asserts that configuration and then moves the camera to watch
# the layers separate.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_there_are_layers_at_different_depths()
	_test_nothing_scrolls_faster_than_the_camera()
	_test_the_layers_only_scroll_sideways()
	_test_the_camera_rides_with_the_player()
	await _test_moving_the_camera_separates_the_layers()
	_test_each_layer_has_something_to_draw()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[parallax-scroll] %d/%d passed" % [_pass, _pass + _fail]
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

func _layers(m: Node2D) -> Array[ParallaxLayer]:
	var found: Array[ParallaxLayer] = []
	for child in m.get_node("ParallaxBackground").get_children():
		if child is ParallaxLayer:
			found.append(child)
	return found

func _test_there_are_layers_at_different_depths() -> void:
	print("the layers")
	var m := _make()
	var layers := _layers(m)
	expect(layers.size() > 2, "there are several layers")

	var scales: Array[float] = []
	for layer in layers:
		scales.append(layer.motion_scale.x)
	# Depth is the whole illusion: identical scales would move as one flat
	# backdrop, however many layers there are.
	var distinct := {}
	for scale in scales:
		distinct[scale] = true
	expect(distinct.size() == layers.size(), "each at its own depth")

	var ordered := true
	for i in scales.size() - 1:
		if scales[i] >= scales[i + 1]:
			ordered = false
	expect(ordered, "listed back to front, the furthest scrolling least")

func _test_nothing_scrolls_faster_than_the_camera() -> void:
	print("depth range")
	var m := _make()
	begin_quiet()
	for layer in _layers(m):
		expect_quiet(layer.motion_scale.x > 0.0, "a layer that does not move at all is not parallax")
		expect_quiet(layer.motion_scale.x < 1.0,
			"a layer at 1.0 or above would sit level with the world or in front of it")
	expect(_quiet_failures == 0, "every layer scrolls, and all of them slower than the world")

func _test_the_layers_only_scroll_sideways() -> void:
	print("axis")
	var m := _make()
	begin_quiet()
	for layer in _layers(m):
		expect_quiet(is_zero_approx(layer.motion_scale.y),
			"a layer drifting vertically would break the horizon")
	expect(_quiet_failures == 0, "the layers scroll sideways only — this demo scrolls sideways")

func _test_the_camera_rides_with_the_player() -> void:
	print("the camera")
	var m := _make()
	expect(m.get_node("Player/Camera2D") != null,
		"the camera is a child of the player, so following costs no code")

func _test_moving_the_camera_separates_the_layers() -> void:
	print("scrolling")
	var m := _make()
	var layers := _layers(m)
	var before: Array[float] = []
	for layer in layers:
		before.append(layer.position.x)

	# The layers follow the camera, which rides on the player — writing
	# scroll_offset by hand is overwritten the moment the background recomputes.
	var player: CharacterBody2D = m.get_node("Player")
	player.global_position += Vector2(600.0, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame

	var moved: Array[float] = []
	for i in layers.size():
		moved.append(absf(layers[i].position.x - before[i]))
	begin_quiet()
	for i in moved.size() - 1:
		expect_quiet(moved[i] < moved[i + 1],
			"layer %d moved %.1f, the one in front moved %.1f" % [i, moved[i], moved[i + 1]])
	expect(_quiet_failures == 0, "walking on moves the near layers further than the far ones")
	expect(moved[moved.size() - 1] > 0.0, "and moves them at all")

func _test_each_layer_has_something_to_draw() -> void:
	print("the artwork")
	var m := _make()
	begin_quiet()
	for layer in _layers(m):
		expect_quiet(layer.get_child_count() > 0, "an empty layer scrolls nothing")
	expect(_quiet_failures == 0, "every layer has something in it to scroll")

var _quiet_failures := 0

## Counted rather than printed, for the checks that run once per layer. Each
## test zeroes the tally first, so one failure cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
