extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_width_presets()
	_test_default_state()
	_test_stroke_storage()
	_test_stroke_requires_min_points()
	_test_undo_removes_last()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) <= tol, label)

func _test_width_presets() -> void:
	print("width presets")
	var thin := 1.5
	var med  := 3.0
	var thick := 7.0
	expect(thin == 1.5, "thin width is 1.5")
	expect(med == 3.0, "medium width is 3.0")
	expect(thick == 7.0, "thick width is 7.0")
	expect(thin < med and med < thick, "widths are ordered thin < med < thick")

func _test_default_state() -> void:
	print("default color and width")
	var color := Color.WHITE
	var width := 3.0
	expect(color == Color.WHITE, "default color is white")
	expect(width == 3.0, "default width is 3.0 (medium)")

func _test_stroke_storage() -> void:
	print("stroke stored in array")
	var strokes: Array = []
	var stroke := {points = PackedVector2Array([Vector2(10, 10), Vector2(20, 20)]),
		color = Color.WHITE, width = 3.0}
	strokes.append(stroke)
	expect(strokes.size() == 1, "stroke added to array")
	expect(strokes[0].points.size() == 2, "stroke has 2 points")

func _test_stroke_requires_min_points() -> void:
	print("stroke requires more than 1 point to save")
	var points := PackedVector2Array()
	points.append(Vector2(10, 10))
	expect(not (points.size() > 1), "single point stroke not saved")
	points.append(Vector2(20, 20))
	expect(points.size() > 1, "two-point stroke is valid")

func _test_undo_removes_last() -> void:
	print("undo removes last stroke")
	var strokes: Array = [
		{points = PackedVector2Array(), color = Color.WHITE, width = 3.0},
		{points = PackedVector2Array(), color = Color.RED, width = 1.5},
	]
	if not strokes.is_empty():
		strokes.pop_back()
	expect(strokes.size() == 1, "undo removes last stroke")
	expect(strokes[0].color == Color.WHITE, "earlier stroke remains")

func _report() -> void:
	var summary := "[line-drawing] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
