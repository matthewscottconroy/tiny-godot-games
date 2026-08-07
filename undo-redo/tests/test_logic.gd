extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_add_stroke_increases_count()
	_test_remove_last_stroke_decreases_count()
	_test_undo_removes_stroke()
	_test_redo_restores_stroke()
	_test_action_name_stored()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# ---- minimal simulation of main.gd logic (no scene tree required) ----

class DrawingModel:
	var strokes: Array = []
	var undo_redo := UndoRedo.new()

	func add_stroke(stroke: PackedVector2Array) -> void:
		strokes.append(stroke)

	func remove_last_stroke() -> void:
		if strokes.size() > 0:
			strokes.pop_back()

	func commit_stroke(stroke: PackedVector2Array) -> void:
		undo_redo.create_action("Draw Stroke")
		undo_redo.add_do_method(self, "add_stroke", stroke)
		undo_redo.add_undo_method(self, "remove_last_stroke")
		undo_redo.commit_action()

	func undo() -> void:
		undo_redo.undo()

	func redo() -> void:
		undo_redo.redo()

func _make_stroke(points: int) -> PackedVector2Array:
	var s := PackedVector2Array()
	for i in range(points):
		s.append(Vector2(i * 10.0, 50.0))
	return s

# ---- tests ----

func _test_add_stroke_increases_count() -> void:
	print("add_stroke increases stroke count")
	var m := DrawingModel.new()
	expect(m.strokes.size() == 0, "starts empty")
	m.add_stroke(_make_stroke(3))
	expect(m.strokes.size() == 1, "count is 1 after add")
	m.add_stroke(_make_stroke(5))
	expect(m.strokes.size() == 2, "count is 2 after second add")

func _test_remove_last_stroke_decreases_count() -> void:
	print("remove_last_stroke decreases stroke count")
	var m := DrawingModel.new()
	m.add_stroke(_make_stroke(4))
	m.add_stroke(_make_stroke(4))
	expect(m.strokes.size() == 2, "two strokes before remove")
	m.remove_last_stroke()
	expect(m.strokes.size() == 1, "one stroke after remove")
	m.remove_last_stroke()
	expect(m.strokes.size() == 0, "empty after second remove")
	m.remove_last_stroke()  # should not crash on empty
	expect(m.strokes.size() == 0, "still empty after remove on empty")

func _test_undo_removes_stroke() -> void:
	print("undo() removes last committed stroke")
	var m := DrawingModel.new()
	m.commit_stroke(_make_stroke(3))
	expect(m.strokes.size() == 1, "one stroke after commit")
	m.undo()
	expect(m.strokes.size() == 0, "zero strokes after undo")

func _test_redo_restores_stroke() -> void:
	print("redo() after undo() restores stroke")
	var m := DrawingModel.new()
	m.commit_stroke(_make_stroke(3))
	m.undo()
	expect(m.strokes.size() == 0, "zero after undo")
	m.redo()
	expect(m.strokes.size() == 1, "one stroke restored after redo")

func _test_action_name_stored() -> void:
	print("UndoRedo stores action name correctly")
	var m := DrawingModel.new()
	m.commit_stroke(_make_stroke(2))
	# get_action_name(0) returns the name of the last committed action
	expect(m.undo_redo.get_action_name(0) == "Draw Stroke", "action name is 'Draw Stroke'")

func _report() -> void:
	var summary := "[undo-redo] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
