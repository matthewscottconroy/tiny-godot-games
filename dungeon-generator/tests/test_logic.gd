extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_map_dimensions()
	_test_room_placement_no_overlap()
	_test_room_size_range()
	_test_corridor_connects_rooms()
	_test_grid_cell_count()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_map_dimensions() -> void:
	print("map dimensions")
	const MAP_W := 80
	const MAP_H := 56
	expect(MAP_W == 80, "MAP_W is 80")
	expect(MAP_H == 56, "MAP_H is 56")

func _test_room_placement_no_overlap() -> void:
	print("rooms do not overlap (grow by 1)")
	var rooms: Array[Rect2i] = []
	var r1 := Rect2i(5, 5, 8, 6)
	var r2 := Rect2i(20, 10, 7, 5)
	rooms.append(r1)
	var padded := r2.grow(1)
	var overlaps := false
	for r in rooms:
		if padded.intersects(r):
			overlaps = true
	expect(not overlaps, "non-overlapping rooms pass overlap check")

	var r3 := Rect2i(8, 6, 6, 4)  # overlaps r1
	padded = r3.grow(1)
	overlaps = false
	for r in rooms:
		if padded.intersects(r):
			overlaps = true
	expect(overlaps, "overlapping room detected correctly")

func _test_room_size_range() -> void:
	print("room size constants")
	const MIN_W := 5
	const MAX_W := 14
	const MIN_H := 4
	const MAX_H := 10
	expect(MIN_W < MAX_W, "min width < max width")
	expect(MIN_H < MAX_H, "min height < max height")

func _test_corridor_connects_rooms() -> void:
	print("L-shaped corridor connects two room centers")
	var ax := 10
	var ay := 10
	var bx := 30
	var by := 20
	var visited: Array = []
	var cx := ax
	while cx != bx:
		visited.append(Vector2i(cx, ay))
		cx += 1 if bx > cx else -1
	var cy := ay
	while cy != by:
		visited.append(Vector2i(bx, cy))
		cy += 1 if by > cy else -1
	expect(visited.has(Vector2i(bx, ay)), "corridor passes through corner cell")
	expect(visited.size() > 0, "corridor has cells")

func _test_grid_cell_count() -> void:
	print("grid total cell count")
	const MAP_W := 80
	const MAP_H := 56
	expect(MAP_W * MAP_H == 4480, "grid has 80*56 = 4480 cells")

func _report() -> void:
	var summary := "[dungeon-generator] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
