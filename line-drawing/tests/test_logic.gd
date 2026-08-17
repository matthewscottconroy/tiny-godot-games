extends Node

# Drives the real canvas from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_canvas_starts_blank()
	_test_a_drag_becomes_a_stroke()
	_test_a_single_click_is_not_a_stroke()
	_test_each_stroke_keeps_the_colour_and_width_it_was_drawn_with()
	_test_changing_colour_does_not_repaint_old_strokes()
	_test_right_click_undoes_the_last_stroke()
	_test_undo_on_a_blank_canvas_is_harmless()
	_test_clearing_removes_everything()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[line-drawing] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _button(m: Node2D, at: Vector2, index: int, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.pressed = pressed
	e.position = at
	m._unhandled_input(e)

func _move(m: Node2D, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	m._unhandled_input(e)

## Draw one stroke of `points` positions, press to release.
func _stroke(m: Node2D, from: Vector2, points: int) -> void:
	_button(m, from, MOUSE_BUTTON_LEFT, true)
	for i in points:
		_move(m, from + Vector2(float(i + 1) * 10.0, 0.0))
	_button(m, from + Vector2(float(points) * 10.0, 0.0), MOUSE_BUTTON_LEFT, false)

func _test_the_canvas_starts_blank() -> void:
	print("a blank canvas")
	var m := _make()
	expect(m._strokes.is_empty(), "nothing has been drawn")
	expect(not m._drawing, "and no stroke is in progress")

func _test_a_drag_becomes_a_stroke() -> void:
	print("drawing")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0), 4)
	expect(m._strokes.size() == 1, "a press-drag-release leaves one stroke")
	expect(m._strokes[0].points.size() == 5, "holding every point the mouse passed through")
	expect(not m._drawing, "and the pen is up again")

	_stroke(m, Vector2(100.0, 300.0), 3)
	expect(m._strokes.size() == 2, "a second drag adds a second stroke")

func _test_a_single_click_is_not_a_stroke() -> void:
	print("clicking")
	var m := _make()
	# A click with no movement is one point, which draws no line — keeping it
	# would litter the canvas with invisible strokes that undo has to chew through.
	_button(m, Vector2(100.0, 200.0), MOUSE_BUTTON_LEFT, true)
	_button(m, Vector2(100.0, 200.0), MOUSE_BUTTON_LEFT, false)
	expect(m._strokes.is_empty(), "a click that never moved is not kept")

func _test_each_stroke_keeps_the_colour_and_width_it_was_drawn_with() -> void:
	print("pen settings")
	var m := _make()
	m._color = Color.TOMATO
	m._width = 7.0
	_stroke(m, Vector2(100.0, 200.0), 3)
	expect(m._strokes[0].color == Color.TOMATO, "the stroke remembers its colour")
	expect(is_equal_approx(m._strokes[0].width, 7.0), "and its width")

func _test_changing_colour_does_not_repaint_old_strokes() -> void:
	print("later changes")
	var m := _make()
	m._color = Color.TOMATO
	_stroke(m, Vector2(100.0, 200.0), 3)
	m._color = Color.CORNFLOWER_BLUE
	m._width = 1.5
	_stroke(m, Vector2(100.0, 300.0), 3)
	expect(m._strokes[0].color == Color.TOMATO, "the first stroke keeps its own colour")
	expect(m._strokes[1].color == Color.CORNFLOWER_BLUE, "and the second gets the new one")
	expect(m._strokes[0].width != m._strokes[1].width, "widths are per-stroke too")

func _test_right_click_undoes_the_last_stroke() -> void:
	print("undo")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0), 3)
	_stroke(m, Vector2(100.0, 300.0), 3)
	var first: Dictionary = m._strokes[0]
	_button(m, Vector2(400.0, 400.0), MOUSE_BUTTON_RIGHT, true)
	expect(m._strokes.size() == 1, "right-click removes the most recent stroke")
	expect(m._strokes[0] == first, "leaving the earlier one alone")

func _test_undo_on_a_blank_canvas_is_harmless() -> void:
	print("undo with nothing to undo")
	var m := _make()
	_button(m, Vector2(400.0, 400.0), MOUSE_BUTTON_RIGHT, true)
	expect(m._strokes.is_empty(), "undoing an empty canvas leaves it empty")

func _test_clearing_removes_everything() -> void:
	print("clear")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0), 3)
	_stroke(m, Vector2(100.0, 300.0), 3)

	var key := InputEventKey.new()
	key.keycode = KEY_C
	key.pressed = true
	m._unhandled_input(key)
	expect(m._strokes.is_empty(), "C wipes the canvas")

	# Mid-stroke, too: the half-drawn line must not survive the clear and get
	# committed when the button comes up.
	var during := _make()
	_button(during, Vector2(100.0, 200.0), MOUSE_BUTTON_LEFT, true)
	_move(during, Vector2(150.0, 200.0))
	during._unhandled_input(key)
	expect(not during._drawing, "clearing mid-stroke puts the pen down")
	_button(during, Vector2(200.0, 200.0), MOUSE_BUTTON_LEFT, false)
	expect(during._strokes.is_empty(), "and the interrupted stroke is not committed")
