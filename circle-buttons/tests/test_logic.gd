extends Node

# Drives the real CircleDisplay control from scripts/circle_display.gd — its
# layout, hit-testing, and click signal — rather than a copy of the maths.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_hit_inside()
	_test_hit_outside()
	_test_hit_edge()
	_test_hit_overlap_priority()
	_test_place_single_centered()
	_test_place_three_symmetric()
	_test_place_gap()
	_test_data_preserved()
	_test_configure_replaces_previous_set()
	_test_click_signal()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

const DISPLAY_SIZE := Vector2(600.0, 200.0)

func _make(specs: Array) -> CircleDisplay:
	var display := CircleDisplay.new()
	display.size = DISPLAY_SIZE
	add_child(display)
	display.configure(specs)
	return display

func _center() -> Vector2:
	return DISPLAY_SIZE * 0.5

func _test_hit_inside() -> void:
	print("hit test: inside a circle")
	var d := _make([{"radius": 40.0, "color": Color.RED}])
	expect(d._hit_test(_center()) == 0, "click at the centre of a single circle hits index 0")

func _test_hit_outside() -> void:
	print("hit test: outside every circle")
	var d := _make([{"radius": 40.0}])
	expect(d._hit_test(Vector2(2.0, 2.0)) == -1, "a click in the corner returns -1")
	expect(_make([])._hit_test(_center()) == -1, "an empty display never reports a hit")

func _test_hit_edge() -> void:
	print("hit test: just past the edge")
	var d := _make([{"radius": 40.0}])
	expect(d._hit_test(_center() + Vector2(39.0, 0.0)) == 0, "just inside the radius hits")
	expect(d._hit_test(_center() + Vector2(41.0, 0.0)) == -1, "just outside the radius misses")

func _test_hit_overlap_priority() -> void:
	print("hit test: overlapping circles")
	# configure() lays circles out with a gap so they never overlap on their own.
	# Force an overlap to check the documented tie-break: the last-drawn circle
	# (highest index) wins, matching what the user sees on top.
	var d := _make([{"radius": 40.0}, {"radius": 40.0}])
	d._circles[1]["_ox"] = d._circles[0]["_ox"]
	d._circles[1]["_oy"] = d._circles[0]["_oy"]
	expect(d._hit_test(d._center_of(d._circles[0])) == 1,
		"overlapping circles: the higher index wins")

func _test_place_single_centered() -> void:
	print("layout: a single circle is centred")
	var d := _make([{"radius": 30.0}])
	expect_near(d._center_of(d._circles[0]).x, _center().x, "one circle sits on the control's centre")

func _test_place_three_symmetric() -> void:
	print("layout: three equal circles are symmetric")
	var d := _make([{"radius": 30.0}, {"radius": 30.0}, {"radius": 30.0}])
	var left := d._center_of(d._circles[0]).x
	var mid := d._center_of(d._circles[1]).x
	var right := d._center_of(d._circles[2]).x
	expect(left < mid and mid < right, "circles are laid out left to right")
	expect_near(mid, _center().x, "the middle circle is centred")
	expect_near(_center().x - left, right - _center().x, "the row is symmetric about the centre")

func _test_place_gap() -> void:
	print("layout: circles are separated by the gap")
	var d := _make([{"radius": 20.0}, {"radius": 20.0}])
	var span: float = d._circles[1]["_ox"] - d._circles[0]["_ox"]
	expect_near(span, 20.0 + 20.0 + 20.0, "adjacent centres are r + r + gap apart")

func _test_data_preserved() -> void:
	print("configure preserves the caller's spec")
	var d := _make([{"radius": 25.0, "color": Color.AQUA, "label": "A", "payload": "extra"}])
	var c: Dictionary = d._circles[0]
	expect(c["label"] == "A", "the label is preserved")
	expect(c["payload"] == "extra", "unknown extra keys are preserved for the click signal")
	expect(c["color"] == Color.AQUA, "the colour is preserved")

func _test_configure_replaces_previous_set() -> void:
	print("configure replaces rather than appends")
	var d := _make([{"radius": 30.0}, {"radius": 30.0}])
	d.configure([{"radius": 10.0}])
	expect(d._circles.size() == 1, "a second configure() call replaces the previous circles")

func _test_click_signal() -> void:
	print("circle_clicked carries the index and the spec")
	var d := _make([{"radius": 40.0, "label": "one", "payload": 7}])
	var seen := {"index": -99, "data": {}}
	d.circle_clicked.connect(func(index: int, data: Dictionary) -> void:
		seen["index"] = index
		seen["data"] = data)

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = _center()
	d._gui_input(event)

	expect(seen["index"] == 0, "the clicked index is reported")
	expect(seen["data"].get("payload") == 7, "the spec — including extra keys — comes back with it")

func _report() -> void:
	var summary := "[circle-buttons] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
