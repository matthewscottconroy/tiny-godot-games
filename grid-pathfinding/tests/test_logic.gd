extends Node

# Drives the real A* from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_grid_starts_open()
	_test_clicks_land_on_the_right_cell()
	_test_cells_off_the_board_are_rejected()
	_test_a_path_across_open_ground_is_direct()
	_test_the_path_is_a_walk_from_start_to_goal()
	_test_the_path_goes_around_a_wall()
	_test_a_walled_in_goal_has_no_path()
	_test_the_path_never_crosses_a_wall()
	_test_clicking_sets_start_then_goal_then_resets()
	_test_walls_can_only_be_drawn_before_the_goal()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[grid-pathfinding] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _centre_of(m: Node2D, cell: Vector2i) -> Vector2:
	return Vector2(m.OFFSET_X + cell.x * m.CELL + m.CELL * 0.5,
		m.OFFSET_Y + cell.y * m.CELL + m.CELL * 0.5)

func _click(m: Node2D, cell: Vector2i, button: int) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = _centre_of(m, cell)
	m._input(e)

func _wall(m: Node2D, cell: Vector2i) -> void:
	m._grid[cell.y][cell.x] = false

## Ask for a path between two cells without going through the mouse.
func _path_between(m: Node2D, from: Vector2i, to: Vector2i) -> Array:
	m._start = from
	m._goal = to
	return m._astar()

func _test_the_grid_starts_open() -> void:
	print("the board")
	var m := _make()
	expect(m._grid.size() == m.ROWS, "the grid has a row per ROWS")
	expect(m._grid[0].size() == m.COLS, "and a column per COLS")
	var all_open := true
	for row in m._grid:
		for cell in row:
			if not cell:
				all_open = false
	expect(all_open, "every cell starts walkable")

func _test_clicks_land_on_the_right_cell() -> void:
	print("hit testing")
	var m := _make()
	for cell in [Vector2i(0, 0), Vector2i(3, 7), Vector2i(m.COLS - 1, m.ROWS - 1)]:
		expect(m._screen_to_cell(_centre_of(m, cell)) == cell,
			"a click in the middle of %s maps back to it" % cell)

func _test_cells_off_the_board_are_rejected() -> void:
	print("bounds")
	var m := _make()
	expect(m._valid(Vector2i(0, 0)), "the top-left corner is on the board")
	expect(m._valid(Vector2i(m.COLS - 1, m.ROWS - 1)), "and so is the bottom-right")
	expect(not m._valid(Vector2i(-1, 0)), "one column left of it is not")
	expect(not m._valid(Vector2i(0, -1)), "nor one row above")
	expect(not m._valid(Vector2i(m.COLS, 0)), "nor one past the right edge")
	expect(not m._valid(Vector2i(0, m.ROWS)), "nor one below the bottom")

func _test_a_path_across_open_ground_is_direct() -> void:
	print("shortest path")
	var m := _make()
	var from := Vector2i(2, 2)
	var to := Vector2i(9, 6)
	var path := _path_between(m, from, to)
	# On an open grid with four-way movement, the shortest route is the
	# Manhattan distance — anything longer means A* took a detour.
	var manhattan: int = absi(to.x - from.x) + absi(to.y - from.y)
	expect(path.size() == manhattan + 1,
		"the path is as short as the grid allows (%d steps)" % manhattan)

func _test_the_path_is_a_walk_from_start_to_goal() -> void:
	print("path shape")
	var m := _make()
	var from := Vector2i(1, 1)
	var to := Vector2i(12, 9)
	var path := _path_between(m, from, to)
	expect(path.size() > 0, "there is a path")
	expect(path[0] == from, "which begins at the start")
	expect(path[path.size() - 1] == to, "and ends at the goal")

	var contiguous := true
	for i in path.size() - 1:
		var step: Vector2i = path[i + 1] - path[i]
		if absi(step.x) + absi(step.y) != 1:
			contiguous = false
	expect(contiguous, "and every step moves exactly one cell — no teleporting")

func _test_the_path_goes_around_a_wall() -> void:
	print("routing")
	var m := _make()
	var from := Vector2i(1, 5)
	var to := Vector2i(5, 5)
	var direct := _path_between(m, from, to).size()

	# A wall straight across the middle of the route.
	for y in range(0, 8):
		_wall(m, Vector2i(3, y))
	var around := _path_between(m, from, to)
	expect(around.size() > direct, "a wall in the way makes the route longer")
	expect(around[around.size() - 1] == to, "but it still reaches the goal")

func _test_a_walled_in_goal_has_no_path() -> void:
	print("no route")
	var m := _make()
	var to := Vector2i(10, 7)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		_wall(m, to + d)
	var path := _path_between(m, Vector2i(1, 1), to)
	expect(path.is_empty(), "a goal walled in on all sides is unreachable")

	var off := _make()
	expect(off._astar().is_empty(), "and asking before the cells are placed gives nothing")

func _test_the_path_never_crosses_a_wall() -> void:
	print("walls hold")
	var m := _make()
	# A barrier with one gap, so the only route is through it.
	for y in range(0, m.ROWS):
		if y != 11:
			_wall(m, Vector2i(6, y))
	var path := _path_between(m, Vector2i(2, 2), Vector2i(12, 2))
	expect(path.size() > 0, "the gap leaves a way through")
	var clear := true
	for cell in path:
		if not m._grid[cell.y][cell.x]:
			clear = false
	expect(clear, "and no step of the path stands on a wall")
	expect(path.has(Vector2i(6, 11)), "so it has to go through the gap")

func _test_clicking_sets_start_then_goal_then_resets() -> void:
	print("placing the ends")
	var m := _make()
	_click(m, Vector2i(2, 2), MOUSE_BUTTON_LEFT)
	expect(m._start == Vector2i(2, 2), "the first click sets the start")
	expect(m._path.is_empty(), "with nothing to path to yet")

	_click(m, Vector2i(8, 5), MOUSE_BUTTON_LEFT)
	expect(m._goal == Vector2i(8, 5), "the second sets the goal")
	expect(m._path.size() > 0, "and the path appears")

	_click(m, Vector2i(4, 4), MOUSE_BUTTON_LEFT)
	expect(m._path.is_empty(), "the third clears it")
	expect(not m._valid(m._start), "along with the start")
	expect(not m._valid(m._goal), "and the goal")

func _test_walls_can_only_be_drawn_before_the_goal() -> void:
	print("drawing walls")
	var m := _make()
	_click(m, Vector2i(4, 4), MOUSE_BUTTON_RIGHT)
	expect(not m._grid[4][4], "right-click puts a wall down")
	_click(m, Vector2i(4, 4), MOUSE_BUTTON_RIGHT)
	expect(m._grid[4][4], "and right-clicking it again takes it away")

	_click(m, Vector2i(1, 1), MOUSE_BUTTON_LEFT)
	_click(m, Vector2i(9, 9), MOUSE_BUTTON_LEFT)
	_click(m, Vector2i(5, 5), MOUSE_BUTTON_RIGHT)
	expect(m._grid[5][5], "once a path is drawn the walls are locked until reset")
