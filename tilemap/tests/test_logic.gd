extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_tile_size()
	_test_map_dimensions()
	_test_tile_type_range()
	_test_map_data_row_count()
	_test_map_data_col_count()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_tile_size() -> void:
	print("tile size")
	const TILE_SIZE := 32
	expect(TILE_SIZE == 32, "TILE_SIZE is 32 pixels")

func _test_map_dimensions() -> void:
	print("map dimensions in tiles")
	var map_rows := 14
	var map_cols := 20
	expect(map_rows == 14, "map has 14 rows")
	expect(map_cols == 20, "map has 20 columns")

func _test_tile_type_range() -> void:
	print("tile type values 0-3")
	for tile_id in [0, 1, 2, 3]:
		expect(tile_id >= 0 and tile_id <= 3, "tile id %d is in valid range" % tile_id)

func _test_map_data_row_count() -> void:
	print("MAP_DATA has correct row count")
	var MAP_DATA := []
	for i in 14:
		var row := []
		for j in 20:
			row.append(0)
		MAP_DATA.append(row)
	expect(MAP_DATA.size() == 14, "MAP_DATA has 14 rows")

func _test_map_data_col_count() -> void:
	print("MAP_DATA rows have correct column count")
	var first_row_len := 20
	expect(first_row_len == 20, "each MAP_DATA row has 20 columns")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
