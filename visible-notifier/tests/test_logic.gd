extends Node

# Drives the real culling from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_grid_is_laid_out()
	_test_every_object_has_a_notifier()
	_test_objects_start_active()
	_test_leaving_the_screen_deactivates_an_object()
	_test_coming_back_reactivates_it()
	_test_the_count_follows()
	_test_only_active_objects_are_animated()
	_test_the_camera_pans_with_the_keys()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[visible-notifier] %d/%d passed" % [_pass, _pass + _fail]
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

func _objects(m: Node2D) -> Array:
	return m.get_node("Objects").get_children()

func _notifier(obj: Node2D) -> VisibleOnScreenNotifier2D:
	for child in obj.get_children():
		if child is VisibleOnScreenNotifier2D:
			return child
	return null

func _count_text(m: Node2D) -> String:
	return (m.get_node("HUD/CountLabel") as Label).text

func _test_the_grid_is_laid_out() -> void:
	print("the field")
	begin_quiet()
	var m := _make()
	expect(_objects(m).size() == m.OBJECT_COUNT, "there is an object per grid cell")
	expect(m.OBJECT_COUNT > 50, "enough of them that culling is worth doing")

	# Laid out inside the drawn field, not off its left edge.
	var field := Rect2(40.0, 90.0, m.COLS * m.SPACING + 40, m.ROWS * m.SPACING + 40)
	for obj in _objects(m):
		expect_quiet(field.has_point(obj.position), "an object sits outside the field at %s" % obj.position)
	expect(_quiet_failures == 0, "every object is laid out inside the field that is drawn for them")

func _test_every_object_has_a_notifier() -> void:
	print("the notifiers")
	begin_quiet()
	var m := _make()
	for obj in _objects(m):
		expect_quiet(_notifier(obj) != null, "an object without a notifier is never culled")
	expect(_quiet_failures == 0, "every object carries a notifier")

	var rect: Rect2 = _notifier(_objects(m)[0]).rect
	expect(rect.size.x > 0.0 and rect.size.y > 0.0, "with a real area to test against the screen")

func _test_objects_start_active() -> void:
	print("before culling")
	begin_quiet()
	var m := _make()
	for obj in _objects(m):
		expect_quiet(obj.get_meta("active"), "an object starts active")
	expect(_quiet_failures == 0, "everything starts active until told otherwise")

func _test_leaving_the_screen_deactivates_an_object() -> void:
	print("going off screen")
	var m := _make()
	var obj: Node2D = _objects(m)[0]
	_notifier(obj).screen_exited.emit()
	expect(not obj.get_meta("active"), "an object that leaves the screen is switched off")

func _test_coming_back_reactivates_it() -> void:
	print("coming back")
	var m := _make()
	var obj: Node2D = _objects(m)[0]
	_notifier(obj).screen_exited.emit()
	_notifier(obj).screen_entered.emit()
	expect(obj.get_meta("active"), "and switched back on when it returns")

func _test_the_count_follows() -> void:
	print("the readout")
	var m := _make()
	var total: int = _objects(m).size()
	expect(_count_text(m).contains(str(total)), "the readout knows how many objects there are")

	for i in 10:
		_notifier(_objects(m)[i]).screen_exited.emit()
	expect(_count_text(m).contains(str(total - 10)),
		"and how many are still being processed")

	# Something in the container that is not one of the culled objects has no
	# "active" flag at all, and must not be counted as if it were on screen.
	var stray := Node2D.new()
	m.get_node("Objects").add_child(stray)
	m._refresh_count()
	expect(_count_text(m).contains(str(total - 10)),
		"a child with no active flag is not counted as active")

func _test_only_active_objects_are_animated() -> void:
	print("the saving")
	var m := _make()
	var awake: Node2D = _objects(m)[0]
	var asleep: Node2D = _objects(m)[1]
	_notifier(asleep).screen_exited.emit()

	var awake_before: float = awake.get_meta("angle")
	var asleep_before: float = asleep.get_meta("angle")
	m._process(STEP)
	# The point of the demo: work skipped for what nobody can see.
	expect(awake.get_meta("angle") > awake_before, "an on-screen object keeps turning, one way")
	expect(asleep.get_meta("angle") == asleep_before, "an off-screen one is left alone")

func _test_the_camera_pans_with_the_keys() -> void:
	print("panning")
	var m := _make()
	var camera: Camera2D = m.get_node("Camera2D")
	var start: Vector2 = camera.position
	m._process(STEP)
	# No keys are held in a headless run, so the camera should sit still rather
	# than drifting on its own.
	expect(camera.position == start, "the camera stays put while nothing is pressed")

var _quiet_failures := 0

## Counted rather than printed, for checks that run once per item. Each test
## zeroes the tally first, so one failure cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
