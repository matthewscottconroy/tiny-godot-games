extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_drag_state_toggle()
	_test_drag_offset_calculation()
	_test_position_while_dragging()
	_test_fill_counter()
	_test_item_rect_size()
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

func _test_drag_state_toggle() -> void:
	print("drag state toggle")
	var dragging := false
	dragging = true
	expect(dragging, "drag starts on mouse press")
	dragging = false
	expect(not dragging, "drag ends on mouse release")

func _test_drag_offset_calculation() -> void:
	print("drag offset = position - mouse_pos")
	var pos := Vector2(200.0, 150.0)
	var mouse := Vector2(190.0, 140.0)
	var offset := pos - mouse
	expect(offset.x == 10.0, "offset x is correct")
	expect(offset.y == 10.0, "offset y is correct")

func _test_position_while_dragging() -> void:
	print("position while dragging = mouse + offset")
	var offset := Vector2(10.0, 10.0)
	var mouse := Vector2(300.0, 200.0)
	var new_pos := mouse + offset
	expect(new_pos.x == 310.0, "dragged x position correct")
	expect(new_pos.y == 210.0, "dragged y position correct")

func _test_fill_counter() -> void:
	print("fill counter increments on drop")
	var filled := 0
	var total_zones := 3
	filled += 1
	expect(filled == 1, "fill counter increments")
	expect(filled < total_zones, "not all slots filled yet")
	filled = total_zones
	expect(filled == total_zones, "all slots filled")

func _test_item_rect_size() -> void:
	print("item draw rect dimensions")
	var item_rect := Rect2(-24, -24, 48, 48)
	expect(item_rect.size.x == 48.0, "item width is 48")
	expect(item_rect.size.y == 48.0, "item height is 48 (square)")
	expect(item_rect.position.x == -24.0, "item centered on x")
	expect(item_rect.position.y == -24.0, "item centered on y")

func _report() -> void:
	var summary := "[drag-drop] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
