extends Node

# Drives the real scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_unzoomed()
	_test_the_wheel_zooms_both_ways()
	_test_the_keyboard_zooms_both_ways()
	_test_reset_returns_to_one()
	_test_zoom_stops_at_the_limits()
	_test_the_camera_eases_towards_the_target()
	_test_events_that_should_be_ignored()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.0001) -> void:
	expect(absf(a - b) < tol, label)

func _report() -> void:
	var summary := "[camera-zoom] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _wheel(button: int) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	return e

func _key(code: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	return e

func _test_it_starts_unzoomed() -> void:
	print("initial zoom")
	var m := _make()
	expect_approx(m.target_zoom(), 1.0, "the target starts at 1x")
	expect(m.ZOOM_MIN < 1.0 and m.ZOOM_MAX > 1.0, "with room to zoom in both directions")

func _test_the_wheel_zooms_both_ways() -> void:
	print("mouse wheel")
	var m := _make()
	m._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	expect_approx(m.target_zoom(), 1.0 + m.ZOOM_STEP, "wheel up zooms in by one step")
	m._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	expect_approx(m.target_zoom(), 1.0, "and wheel down undoes it")

func _test_the_keyboard_zooms_both_ways() -> void:
	print("keyboard")
	var m := _make()
	m._unhandled_input(_key(KEY_EQUAL))
	expect_approx(m.target_zoom(), 1.0 + m.ZOOM_STEP, "= zooms in")
	m._unhandled_input(_key(KEY_MINUS))
	expect_approx(m.target_zoom(), 1.0, "and - zooms back out")

	var pad := _make()
	pad._unhandled_input(_key(KEY_KP_ADD))
	expect_approx(pad.target_zoom(), 1.0 + pad.ZOOM_STEP, "the numpad keys work too")
	pad._unhandled_input(_key(KEY_KP_SUBTRACT))
	expect_approx(pad.target_zoom(), 1.0, "in both directions")

func _test_reset_returns_to_one() -> void:
	print("reset")
	var m := _make()
	for i in 5:
		m._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	expect(m.target_zoom() > 1.0, "zoomed in a long way")
	m._unhandled_input(_key(KEY_R))
	expect_approx(m.target_zoom(), 1.0, "R goes straight back to 1x")

func _test_zoom_stops_at_the_limits() -> void:
	print("limits")
	# Spinning the wheel forever must not invert or run away — the clamp is what
	# keeps the camera usable.
	var into := _make()
	for i in 100:
		into._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	expect_approx(into.target_zoom(), into.ZOOM_MAX, "zooming in stops at the maximum")

	var out_of := _make()
	for i in 100:
		out_of._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	expect_approx(out_of.target_zoom(), out_of.ZOOM_MIN, "and zooming out at the minimum")
	expect(out_of.ZOOM_MIN > 0.0, "which is above zero — a zero zoom shows nothing")

func _test_the_camera_eases_towards_the_target() -> void:
	print("easing")
	var m := _make()
	var camera: Camera2D = m.get_node("Camera2D")
	m._unhandled_input(_key(KEY_R))
	camera.zoom = Vector2(1.0, 1.0)
	for i in 4:
		m._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	var target: float = m.target_zoom()

	m._process(1.0 / 60.0)
	var after_one: float = camera.zoom.x
	expect(after_one > 1.0, "one frame moves the camera towards the target")
	expect(after_one < target, "but does not snap it there — that is the smoothing")

	for i in 120:
		m._process(1.0 / 60.0)
	expect(absf(camera.zoom.x - target) < 0.01, "it arrives given enough frames")
	expect_approx(camera.zoom.x, camera.zoom.y, "and stays square — no accidental stretching")

func _test_events_that_should_be_ignored() -> void:
	print("events that are not zoom input")
	var m := _make()

	# Holding + repeats the key. Acting on the repeats would make the zoom run
	# away from a single held press.
	m._unhandled_input(_key(KEY_EQUAL, true, true))
	expect_approx(m.target_zoom(), 1.0, "an auto-repeat echo does not zoom")

	m._unhandled_input(_key(KEY_EQUAL, false))
	expect_approx(m.target_zoom(), 1.0, "nor does releasing the key")

	m._unhandled_input(_key(KEY_Q))
	expect_approx(m.target_zoom(), 1.0, "nor an unrelated key")

	# Each wheel notch sends a press and a release; counting both would double
	# every step.
	var release := _wheel(MOUSE_BUTTON_WHEEL_DOWN)
	release.pressed = false
	m._unhandled_input(release)
	expect_approx(m.target_zoom(), 1.0, "and the release half of a wheel notch is ignored")
