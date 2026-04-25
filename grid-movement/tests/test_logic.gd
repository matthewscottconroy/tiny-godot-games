extends Node

# Run: open test.tscn in Godot and check the Output panel.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_border_cells_are_walls()
	test_interior_cells_passable()
	test_interior_walls_blocked()
	test_cell_to_world_origin()
	test_cell_to_world_center()
	_report()

# --- helpers ---

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[grid-movement] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

# Replicate the wall-building logic from main.gd so tests are self-contained.
func _build_walls() -> Dictionary:
	const COLS := 16
	const ROWS := 12
	var walls : Dictionary = {}
	for x in COLS:
		walls[Vector2i(x, 0)]        = true
		walls[Vector2i(x, ROWS - 1)] = true
	for y in ROWS:
		walls[Vector2i(0, y)]        = true
		walls[Vector2i(COLS - 1, y)] = true
	for w in [Vector2i(4,2),Vector2i(4,3),Vector2i(4,4),Vector2i(4,5),
			  Vector2i(8,3),Vector2i(8,4),Vector2i(8,5),Vector2i(8,6),Vector2i(8,7),
			  Vector2i(11,2),Vector2i(11,3),Vector2i(12,3),Vector2i(12,4),
			  Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
			  Vector2i(3,9),Vector2i(3,10),Vector2i(13,7),Vector2i(14,7)]:
		walls[w] = true
	return walls

func _cell_to_world(cell: Vector2i) -> Vector2:
	const CELL := 40
	return Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)

# --- tests ---

func test_border_cells_are_walls() -> void:
	var walls := _build_walls()
	expect(walls.has(Vector2i(0, 0)),   "top-left corner is wall")
	expect(walls.has(Vector2i(15, 0)),  "top-right corner is wall")
	expect(walls.has(Vector2i(0, 11)),  "bottom-left corner is wall")
	expect(walls.has(Vector2i(15, 11)), "bottom-right corner is wall")
	expect(walls.has(Vector2i(7, 0)),   "top border mid-cell is wall")
	expect(walls.has(Vector2i(7, 11)),  "bottom border mid-cell is wall")

func test_interior_cells_passable() -> void:
	var walls := _build_walls()
	expect(not walls.has(Vector2i(2, 6)),  "player start (2,6) is passable")
	expect(not walls.has(Vector2i(5, 5)),  "open interior (5,5) is passable")
	expect(not walls.has(Vector2i(10, 9)), "open interior (10,9) is passable")

func test_interior_walls_blocked() -> void:
	var walls := _build_walls()
	expect(walls.has(Vector2i(4, 3)), "interior wall (4,3) is blocked")
	expect(walls.has(Vector2i(8, 5)), "interior wall (8,5) is blocked")
	expect(walls.has(Vector2i(6, 8)), "interior wall (6,8) is blocked")

func test_cell_to_world_origin() -> void:
	var pos := _cell_to_world(Vector2i(0, 0))
	expect(pos == Vector2(20, 20), "cell (0,0) maps to world (20,20)")

func test_cell_to_world_center() -> void:
	var pos := _cell_to_world(Vector2i(8, 6))
	expect(pos == Vector2(340, 260), "cell (8,6) maps to world center (340,260)")
