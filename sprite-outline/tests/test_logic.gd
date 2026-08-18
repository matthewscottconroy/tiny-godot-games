extends Node

# Drives the real picking from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_shapes_are_laid_out()
	_test_nothing_is_picked_to_start_with()
	_test_hovering_a_shape_highlights_it()
	_test_hovering_the_gap_highlights_nothing()
	_test_overlapping_shapes_pick_the_nearest_centre()
	_test_clicking_selects()
	_test_a_mouse_release_does_not_select()
	_test_clicking_the_same_shape_again_deselects()
	_test_clicking_another_shape_moves_the_selection()
	_test_clicking_empty_space_clears_the_selection()
	_test_escape_clears_the_selection()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[sprite-outline] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _hover(m: Node2D, at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	m._input(e)

func _click(m: Node2D, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	m._input(e)

func _escape(m: Node2D) -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	m._input(e)

func _centre(m: Node2D, i: int) -> Vector2:
	return m._shapes[i]["pos"]

## Somewhere with no shape under it.
func _empty_space() -> Vector2:
	return Vector2(600.0, 440.0)

func _test_the_shapes_are_laid_out() -> void:
	print("the shapes")
	var m := _make()
	expect(m._shapes.size() > 2, "there are several shapes to pick between")
	begin_quiet()
	for shape in m._shapes:
		expect_quiet(shape["radius"] > 0.0, "a shape has no size to click on")
	expect(_quiet_failures == 0, "every shape has a size")

func _test_nothing_is_picked_to_start_with() -> void:
	print("before the mouse moves")
	var m := _make()
	expect(m._hovered == -1, "nothing is hovered")
	expect(m._selected == -1, "and nothing is selected")

func _test_hovering_a_shape_highlights_it() -> void:
	print("hovering")
	var m := _make()
	begin_quiet()
	for i in m._shapes.size():
		_hover(m, _centre(m, i))
		expect_quiet(m._hovered == i, "hovering shape %d highlighted %d instead" % [i, m._hovered])
	expect(_quiet_failures == 0, "the cursor over a shape highlights that shape")

	# Just inside the edge counts, just outside does not.
	var shape: Dictionary = m._shapes[0]
	_hover(m, shape["pos"] + Vector2(shape["radius"] - 2.0, 0.0))
	expect(m._hovered == 0, "the edge of a shape is still the shape")
	_hover(m, shape["pos"] + Vector2(shape["radius"] + 4.0, 0.0))
	expect(m._hovered == -1, "and just past it is not")

func _test_hovering_the_gap_highlights_nothing() -> void:
	print("hovering the background")
	var m := _make()
	_hover(m, _centre(m, 0))
	_hover(m, _empty_space())
	expect(m._hovered == -1, "moving off the shapes clears the highlight")

func _test_overlapping_shapes_pick_the_nearest_centre() -> void:
	print("overlapping shapes")
	var m := _make()
	# Two shapes on top of each other: the cursor is inside both, and the one
	# whose centre is closer should win rather than whichever comes first.
	m._shapes[0]["pos"] = Vector2(200.0, 200.0)
	m._shapes[0]["radius"] = 60.0
	m._shapes[1]["pos"] = Vector2(240.0, 200.0)
	m._shapes[1]["radius"] = 60.0
	_hover(m, Vector2(235.0, 200.0))
	expect(m._hovered == 1, "the shape whose centre is nearest takes the hover")
	_hover(m, Vector2(205.0, 200.0))
	expect(m._hovered == 0, "and the other one when the cursor moves across")

func _test_clicking_selects() -> void:
	print("selecting")
	var m := _make()
	_click(m, _centre(m, 2))
	expect(m._selected == 2, "clicking a shape selects it")

func _test_a_mouse_release_does_not_select() -> void:
	print("releases")
	var m := _make()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = _centre(m, 2)
	m._input(release)
	# Acting on both halves of a click toggles twice and nothing ever stays
	# selected.
	expect(m._selected == -1, "letting go of the button selects nothing")

	_click(m, _centre(m, 2))
	m._input(release)
	expect(m._selected == 2, "and does not clear a selection either")

func _test_clicking_the_same_shape_again_deselects() -> void:
	print("toggling")
	var m := _make()
	_click(m, _centre(m, 2))
	_click(m, _centre(m, 2))
	expect(m._selected == -1, "clicking the selected shape again lets it go")

func _test_clicking_another_shape_moves_the_selection() -> void:
	print("moving the selection")
	var m := _make()
	_click(m, _centre(m, 2))
	_click(m, _centre(m, 4))
	expect(m._selected == 4, "clicking another shape selects that one instead")

func _test_clicking_empty_space_clears_the_selection() -> void:
	print("clicking away")
	var m := _make()
	_click(m, _centre(m, 2))
	_click(m, _empty_space())
	expect(m._selected == -1, "clicking the background clears the selection")

func _test_escape_clears_the_selection() -> void:
	print("escape")
	var m := _make()
	_click(m, _centre(m, 3))
	expect(m._selected == 3, "selected")
	_escape(m)
	expect(m._selected == -1, "escape clears it")

	var released := _make()
	_click(released, _centre(released, 3))
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = false
	released._input(key)
	expect(released._selected == 3, "and letting go of escape does not clear it a second time")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
