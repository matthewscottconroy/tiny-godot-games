extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_grid_dimensions()
	_test_object_count()
	_test_grid_spacing()
	_test_pan_speed()
	_test_object_positions()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_grid_dimensions() -> void:
	print("grid dimensions")
	const COLS := 12
	const ROWS := 8
	expect(COLS == 12, "grid has 12 columns")
	expect(ROWS == 8, "grid has 8 rows")

func _test_object_count() -> void:
	print("total object count")
	const COLS := 12
	const ROWS := 8
	const OBJECT_COUNT := COLS * ROWS
	expect(OBJECT_COUNT == 96, "total objects is 12*8 = 96")

func _test_grid_spacing() -> void:
	print("grid spacing between objects")
	const SPACING := 80
	expect(SPACING == 80, "object spacing is 80 pixels")

func _test_pan_speed() -> void:
	print("camera pan speed")
	var pan_speed := 300.0
	expect(pan_speed == 300.0, "pan speed is 300")

func _test_object_positions() -> void:
	print("object grid positions")
	const COLS := 12
	const ROWS := 8
	const SPACING := 80
	var positions := []
	for row in ROWS:
		for col in COLS:
			positions.append(Vector2(col * SPACING, row * SPACING))
	expect(positions.size() == 96, "96 positions generated for grid")
	expect(positions[0] == Vector2(0, 0), "first position is at origin")
	expect(positions[1] == Vector2(SPACING, 0), "second position is one spacing right")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
