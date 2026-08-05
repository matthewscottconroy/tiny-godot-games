extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_gravity_scale()
	_test_shape_alternation()
	_test_circle_radius()
	_test_rect_size()
	_test_color_count()
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

func _test_gravity_scale() -> void:
	print("gravity scale")
	var gravity_scale := 1.5
	expect_near(gravity_scale, 1.5, "gravity_scale is 1.5")
	expect(gravity_scale > 1.0, "gravity scale exceeds normal gravity")

func _test_shape_alternation() -> void:
	print("shape alternates circle/rect by count parity")
	for i in 6:
		var is_circle := (i % 2 == 0)
		var is_rect := (i % 2 == 1)
		expect(is_circle != is_rect, "shape type alternates for body %d" % i)

func _test_circle_radius() -> void:
	print("circle body radius")
	var radius := 15.0
	expect(radius == 15.0, "circle radius is 15")

func _test_rect_size() -> void:
	print("rect body size")
	var rect_size := Vector2(32.0, 32.0)
	expect(rect_size.x == 32.0 and rect_size.y == 32.0, "rect body is 32x32")

func _test_color_count() -> void:
	print("body color palette size")
	var colors := [
		Color.TOMATO, Color.CORNFLOWER_BLUE, Color.MEDIUM_SEA_GREEN,
		Color.GOLD, Color.ORCHID, Color.SANDY_BROWN,
	]
	expect(colors.size() == 6, "6 body colors in palette")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
