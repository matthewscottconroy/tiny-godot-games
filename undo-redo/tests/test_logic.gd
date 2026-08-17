extends Node

# Drives the real canvas from scripts/main.gd — see docs/TEST_INTEGRITY.md.
#
# The lesson is Godot's UndoRedo: strokes are committed as actions with a do
# and an undo, so the suite drives the real UndoRedo rather than keeping its own
# stack alongside it.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_canvas_starts_blank()
	_test_a_drag_commits_a_stroke()
	_test_a_click_that_never_moved_is_not_a_stroke()
	_test_undo_takes_the_last_stroke_back()
	_test_redo_puts_it_back()
	_test_undo_walks_all_the_way_back()
	_test_undoing_past_the_start_is_harmless()
	_test_a_new_stroke_discards_the_redo_branch()
	_test_the_counter_follows_the_strokes()
	_test_clearing_wipes_the_history_too()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[undo-redo] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _stroke(m: Node2D, from: Vector2, points: int = 4) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	m._input(down)
	for i in points:
		var motion := InputEventMouseMotion.new()
		motion.position = from + Vector2(float(i + 1) * 10.0, 0.0)
		m._input(motion)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = from + Vector2(float(points) * 10.0, 0.0)
	m._input(up)

func _key(m: Node2D, code: Key, shift: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	e.ctrl_pressed = true
	e.shift_pressed = shift
	m._unhandled_key_input(e)

func _undo(m: Node2D) -> void:
	_key(m, KEY_Z)

func _redo(m: Node2D) -> void:
	_key(m, KEY_Y)

func _test_the_canvas_starts_blank() -> void:
	print("a blank canvas")
	var m := _make()
	expect(m._strokes.is_empty(), "nothing drawn yet")
	expect(not m._drawing, "and no stroke in progress")

func _test_a_drag_commits_a_stroke() -> void:
	print("drawing")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0))
	expect(m._strokes.size() == 1, "a press-drag-release commits one stroke")
	_stroke(m, Vector2(100.0, 300.0))
	expect(m._strokes.size() == 2, "and a second drag another")

func _test_a_click_that_never_moved_is_not_a_stroke() -> void:
	print("clicking")
	var m := _make()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(100.0, 200.0)
	m._input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(100.0, 200.0)
	m._input(up)
	expect(m._strokes.is_empty(), "a single point draws no line, so nothing is committed")

func _test_undo_takes_the_last_stroke_back() -> void:
	print("undo")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0))
	_stroke(m, Vector2(100.0, 300.0))
	_undo(m)
	expect(m._strokes.size() == 1, "ctrl-Z removes the most recent stroke")

func _test_redo_puts_it_back() -> void:
	print("redo")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0))
	_undo(m)
	expect(m._strokes.is_empty(), "undone")
	_redo(m)
	expect(m._strokes.size() == 1, "ctrl-Y brings the stroke back")

	var shifted := _make()
	_stroke(shifted, Vector2(100.0, 200.0))
	_undo(shifted)
	_key(shifted, KEY_Z, true)
	expect(shifted._strokes.size() == 1, "and so does ctrl-shift-Z")

func _test_undo_walks_all_the_way_back() -> void:
	print("undoing repeatedly")
	var m := _make()
	for i in 4:
		_stroke(m, Vector2(100.0, 150.0 + i * 40.0))
	expect(m._strokes.size() == 4, "four strokes drawn")
	for i in 4:
		_undo(m)
	expect(m._strokes.is_empty(), "and undone one at a time back to a blank canvas")
	for i in 4:
		_redo(m)
	expect(m._strokes.size() == 4, "then redone the same way")

func _test_undoing_past_the_start_is_harmless() -> void:
	print("the end of the history")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0))
	for i in 5:
		_undo(m)
	expect(m._strokes.is_empty(), "undoing more times than there are strokes leaves it blank")
	_redo(m)
	expect(m._strokes.size() == 1, "and the history is still intact afterwards")

func _test_a_new_stroke_discards_the_redo_branch() -> void:
	print("branching")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0))
	_stroke(m, Vector2(100.0, 300.0))
	_undo(m)
	# Drawing after an undo replaces the future, as in any editor.
	_stroke(m, Vector2(100.0, 400.0))
	var after_new: int = m._strokes.size()
	_redo(m)
	expect(m._strokes.size() == after_new, "redo has nothing left to replay after a new stroke")

func _test_the_counter_follows_the_strokes() -> void:
	print("the readout")
	var m := _make()
	var label: Label = m.get_node("HUD/HistoryLabel")
	expect(label.text.contains("0"), "the counter starts at zero")
	_stroke(m, Vector2(100.0, 200.0))
	expect(label.text.contains("1"), "and counts a committed stroke")
	_undo(m)
	expect(label.text.contains("0"), "and an undone one back off again")

func _test_clearing_wipes_the_history_too() -> void:
	print("clear")
	var m := _make()
	_stroke(m, Vector2(100.0, 200.0))
	_stroke(m, Vector2(100.0, 300.0))
	m._clear_all()
	expect(m._strokes.is_empty(), "clear empties the canvas")
	# The history goes with it: undoing back into a cleared canvas would put
	# strokes back that the user deliberately threw away.
	_undo(m)
	expect(m._strokes.is_empty(), "and undo cannot resurrect the cleared strokes")
