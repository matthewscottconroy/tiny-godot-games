extends Node

# Drives the real editor from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_opens_with_a_polygon()
	_test_the_area_is_the_shoelace_of_the_points()
	_test_area_does_not_depend_on_winding()
	_test_clicking_a_vertex_grabs_it()
	_test_dragging_moves_the_grabbed_vertex()
	_test_releasing_lets_go()
	_test_right_click_inserts_a_vertex_on_the_nearest_edge()
	_test_a_click_far_from_any_edge_inserts_nothing()
	_test_middle_click_deletes_a_vertex()
	_test_a_triangle_cannot_be_cut_down_further()
	_test_convex_hull_swallows_a_dent()
	_test_reset_puts_the_starting_shape_back()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[polygon-clip] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _click(m: Node2D, at: Vector2, button: int, pressed: bool = true) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.position = at
	m._unhandled_input(e)

func _move(m: Node2D, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	m._unhandled_input(e)

func _test_it_opens_with_a_polygon() -> void:
	print("the starting shape")
	var m := _make()
	expect(m.poly.polygon.size() > 3, "there is a polygon to edit")
	expect(m._drag_idx == -1, "with nothing grabbed")

func _test_the_area_is_the_shoelace_of_the_points() -> void:
	print("area")
	var m := _make()
	# A 100x50 rectangle, whose area is not in doubt.
	var rect := PackedVector2Array([
		Vector2(0, 0), Vector2(100, 0), Vector2(100, 50), Vector2(0, 50)])
	expect(is_equal_approx(absf(m._polygon_area(rect)), 5000.0), "a 100x50 box measures 5000")

	var triangle := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(0, 100)])
	expect(is_equal_approx(absf(m._polygon_area(triangle)), 5000.0), "and half a 100x100 box the same")

func _test_area_does_not_depend_on_winding() -> void:
	print("winding")
	var m := _make()
	var clockwise := PackedVector2Array([
		Vector2(0, 0), Vector2(100, 0), Vector2(100, 50), Vector2(0, 50)])
	var widdershins := PackedVector2Array([
		Vector2(0, 50), Vector2(100, 50), Vector2(100, 0), Vector2(0, 0)])
	# The shoelace formula is signed: the sign is the winding order, and the
	# demo takes the absolute value so the readout is never negative.
	expect(m._polygon_area(clockwise) * m._polygon_area(widdershins) < 0.0,
		"reversing the points flips the sign")
	expect(is_equal_approx(absf(m._polygon_area(clockwise)), absf(m._polygon_area(widdershins))),
		"but not the area")

func _test_clicking_a_vertex_grabs_it() -> void:
	print("grabbing")
	var m := _make()
	_click(m, m.poly.polygon[2], MOUSE_BUTTON_LEFT)
	expect(m._drag_idx == 2, "clicking on a vertex picks up that vertex")

	var missed := _make()
	_click(missed, Vector2(5.0, 5.0), MOUSE_BUTTON_LEFT)
	expect(missed._drag_idx == -1, "clicking empty space picks up nothing")

func _test_dragging_moves_the_grabbed_vertex() -> void:
	print("dragging")
	var m := _make()
	_click(m, m.poly.polygon[2], MOUSE_BUTTON_LEFT)
	var target := Vector2(500.0, 100.0)
	_move(m, target)
	expect(m.poly.polygon[2] == target, "the grabbed vertex follows the mouse")

	var others_moved := false
	for i in m.poly.polygon.size():
		if i != 2 and m.poly.polygon[i] == target:
			others_moved = true
	expect(not others_moved, "and the others stay where they were")

func _test_releasing_lets_go() -> void:
	print("releasing")
	var m := _make()
	_click(m, m.poly.polygon[2], MOUSE_BUTTON_LEFT)
	_click(m, m.poly.polygon[2], MOUSE_BUTTON_LEFT, false)
	expect(m._drag_idx == -1, "releasing drops the vertex")
	var before: PackedVector2Array = m.poly.polygon.duplicate()
	_move(m, Vector2(10.0, 10.0))
	expect(m.poly.polygon == before, "after which moving the mouse changes nothing")

func _test_right_click_inserts_a_vertex_on_the_nearest_edge() -> void:
	print("inserting")
	var m := _make()
	var before: int = m.poly.polygon.size()
	# Halfway along the first edge, so it is unambiguously the nearest one.
	var midpoint: Vector2 = (m.poly.polygon[0] + m.poly.polygon[1]) * 0.5
	_click(m, midpoint, MOUSE_BUTTON_RIGHT)
	expect(m.poly.polygon.size() == before + 1, "right-clicking an edge adds a vertex")
	expect(m.poly.polygon[1] == midpoint, "inserted between the two ends of that edge, not appended")

func _test_a_click_far_from_any_edge_inserts_nothing() -> void:
	print("missing the edge")
	var m := _make()
	var before: int = m.poly.polygon.size()
	_click(m, Vector2(320.0, 260.0), MOUSE_BUTTON_RIGHT)
	expect(m.poly.polygon.size() == before, "a click in the middle of the shape adds nothing")

func _test_middle_click_deletes_a_vertex() -> void:
	print("deleting")
	var m := _make()
	var before: int = m.poly.polygon.size()
	var doomed: Vector2 = m.poly.polygon[2]
	_click(m, doomed, MOUSE_BUTTON_MIDDLE)
	expect(m.poly.polygon.size() == before - 1, "middle-clicking a vertex removes it")
	expect(not m.poly.polygon.has(doomed), "the right one")

	var missed := _make()
	var count: int = missed.poly.polygon.size()
	_click(missed, Vector2(5.0, 5.0), MOUSE_BUTTON_MIDDLE)
	expect(missed.poly.polygon.size() == count, "and middle-clicking nothing removes nothing")

func _test_a_triangle_cannot_be_cut_down_further() -> void:
	print("the floor of three")
	var m := _make()
	m.poly.polygon = PackedVector2Array([Vector2(100, 100), Vector2(300, 120), Vector2(200, 300)])
	_click(m, Vector2(200.0, 300.0), MOUSE_BUTTON_MIDDLE)
	expect(m.poly.polygon.size() == 3, "a triangle keeps all three corners — two points is not a shape")

func _test_convex_hull_swallows_a_dent() -> void:
	print("the convex hull")
	var m := _make()
	# A square with one corner pushed inwards. The hull should drop that point.
	var dent := Vector2(200, 200)
	m.poly.polygon = PackedVector2Array([
		Vector2(100, 100), Vector2(300, 100), dent, Vector2(300, 300), Vector2(100, 300)])
	var before: float = absf(m._polygon_area(m.poly.polygon))
	m._convexify()
	expect(not m.poly.polygon.has(dent), "the dented corner is dropped from the hull")
	expect(absf(m._polygon_area(m.poly.polygon)) > before, "which makes the shape bigger, not smaller")

func _test_reset_puts_the_starting_shape_back() -> void:
	print("reset")
	var m := _make()
	var original: PackedVector2Array = m.poly.polygon.duplicate()
	_click(m, m.poly.polygon[0], MOUSE_BUTTON_LEFT)
	_move(m, Vector2(20.0, 20.0))
	expect(m.poly.polygon != original, "the shape has been edited")
	m._reset()
	expect(m.poly.polygon == original, "reset restores the shape it started with")
	expect(m._drag_idx == -1, "and lets go of anything held")
