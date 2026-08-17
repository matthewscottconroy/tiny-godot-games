extends Node

# Drives the real curve from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_curve_starts_and_ends_on_its_endpoints()
	_test_the_curve_stays_inside_its_hull()
	_test_the_midpoint_is_the_bezier_average()
	_test_moving_a_handle_bends_the_curve()
	_test_the_tangent_points_along_the_curve()
	_test_the_tangent_is_a_direction()
	_test_a_degenerate_curve_still_gives_a_direction()
	_test_dragging_a_control_point()
	_test_clicking_away_grabs_nothing()
	_test_the_dot_loops_around_the_curve()
	_test_a_resets_the_shape()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[bezier-path] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _click(m: Node2D, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	m._input(e)

func _move(m: Node2D, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	m._input(e)

func _test_the_curve_starts_and_ends_on_its_endpoints() -> void:
	print("the ends")
	var m := _make()
	expect(m._bezier(0.0).is_equal_approx(m._points[0]), "t=0 is the first control point")
	expect(m._bezier(1.0).is_equal_approx(m._points[3]), "t=1 is the last")

func _test_the_curve_stays_inside_its_hull() -> void:
	print("the convex hull")
	var m := _make()
	# A cubic Bezier never leaves the box around its four control points. This
	# is the property that makes the handles predictable to drag.
	# Grown by a hair, because Rect2.has_point excludes the far edges and the
	# curve touches them exactly at t=0 and t=1.
	var box := Rect2(m._points[0], Vector2.ZERO)
	for i in 4:
		box = box.expand(m._points[i])
	box = box.grow(0.001)
	var inside := true
	for i in 101:
		if not box.has_point(m._bezier(float(i) / 100.0)):
			inside = false
	expect(inside, "no point on the curve escapes the box around the control points")

func _test_the_midpoint_is_the_bezier_average() -> void:
	print("the middle")
	var m := _make()
	# At t=0.5 the cubic reduces to (p0 + 3p1 + 3p2 + p3) / 8 — worked out
	# independently of the code rather than by calling it again.
	var expected: Vector2 = (m._points[0] + m._points[1] * 3.0 + m._points[2] * 3.0 + m._points[3]) / 8.0
	expect(m._bezier(0.5).is_equal_approx(expected), "the halfway point matches the formula")

func _test_moving_a_handle_bends_the_curve() -> void:
	print("handles")
	var m := _make()
	var before: Vector2 = m._bezier(0.5)
	var pts: PackedVector2Array = m._points
	pts[1] = pts[1] + Vector2(0.0, -200.0)
	m._points = pts
	expect(m._bezier(0.5).y < before.y, "pulling a handle up lifts the middle of the curve")
	expect(m._bezier(0.0).is_equal_approx(m._points[0]), "without moving the ends")

func _test_the_tangent_points_along_the_curve() -> void:
	print("the tangent")
	var m := _make()
	for t in [0.1, 0.35, 0.6, 0.9]:
		var here: Vector2 = m._bezier(t)
		var just_after: Vector2 = m._bezier(t + 0.01)
		var tangent: Vector2 = m._bezier_tangent(t)
		expect(tangent.dot((just_after - here).normalized()) > 0.9,
			"at t=%.2f the tangent points the way the curve is going" % t)

func _test_the_tangent_is_a_direction() -> void:
	print("normalisation")
	var m := _make()
	var unit := true
	for i in 21:
		if not is_equal_approx(m._bezier_tangent(float(i) / 20.0).length(), 1.0):
			unit = false
	expect(unit, "the tangent is a unit vector, whatever the curve is doing")

func _test_a_degenerate_curve_still_gives_a_direction() -> void:
	print("a curve with no length")
	var m := _make()
	# All four points on top of each other: the tangent is undefined, and
	# normalising a zero vector would hand back a NaN.
	m._points = PackedVector2Array([Vector2(100, 100), Vector2(100, 100), Vector2(100, 100), Vector2(100, 100)])
	var tangent: Vector2 = m._bezier_tangent(0.5)
	expect(not is_nan(tangent.x) and not is_nan(tangent.y), "no NaN comes out of it")
	expect(is_equal_approx(tangent.length(), 1.0), "just a fallback direction")

func _test_dragging_a_control_point() -> void:
	print("dragging")
	var m := _make()
	_click(m, m._points[1], true)
	expect(m._drag == 1, "clicking a control point picks it up")
	_move(m, Vector2(300.0, 50.0))
	expect(m._points[1] == Vector2(300.0, 50.0), "and the mouse carries it")
	_click(m, Vector2(300.0, 50.0), false)
	expect(m._drag == -1, "releasing puts it down")
	_move(m, Vector2(10.0, 10.0))
	expect(m._points[1] == Vector2(300.0, 50.0), "after which it stays where it was left")

func _test_clicking_away_grabs_nothing() -> void:
	print("missing")
	var m := _make()
	_click(m, Vector2(320.0, 240.0), true)
	expect(m._drag == -1, "a click away from every control point grabs nothing")
	var before: PackedVector2Array = m._points.duplicate()
	_move(m, Vector2(10.0, 10.0))
	expect(m._points == before, "so moving the mouse changes nothing")

func _test_the_dot_loops_around_the_curve() -> void:
	print("the travelling dot")
	var m := _make()
	m._t = 0.0
	m._process(1.0)
	expect(m._t > 0.0 and m._t < 1.0, "the dot advances along the curve")
	for i in 600:
		m._process(STEP)
	expect(m._t >= 0.0 and m._t < 1.0, "and wraps round rather than running off the end")

func _test_a_resets_the_shape() -> void:
	print("reset")
	var m := _make()
	var pts: PackedVector2Array = m._points
	pts[2] = Vector2(20.0, 20.0)
	m._points = pts
	var e := InputEventKey.new()
	e.keycode = KEY_A
	e.pressed = true
	m._input(e)
	for i in 4:
		expect(m._points[i] == m.DEFAULT_POINTS[i], "A puts control point %d back" % i)
