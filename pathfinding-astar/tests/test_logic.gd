extends Node

# Drives the real A* from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_opens_with_a_path()
	_test_the_path_is_a_walk_from_start_to_goal()
	_test_an_open_grid_gives_the_shortest_route()
	_test_the_heuristic_is_the_manhattan_distance()
	_test_neighbours_are_the_four_open_cells_around_a_cell()
	_test_a_wall_makes_the_route_longer()
	_test_a_walled_off_goal_has_no_path()
	_test_the_path_never_stands_on_a_wall()
	_test_the_search_does_not_explore_the_whole_grid()
	_test_clicking_toggles_a_wall()
	_test_the_start_and_goal_cannot_be_walled_over()
	_test_the_start_and_goal_cannot_be_put_on_each_other()
	_test_moving_an_end_repaths()
	_test_tab_cycles_the_placement_mode()
	_test_c_clears_the_walls()
	_test_shift_click_moves_the_goal()
	_test_the_placement_modes_place_what_they_say()
	_test_r_scatters_walls_without_burying_the_ends()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[pathfinding-astar] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _centre_of(m: Node2D, cell: Vector2i) -> Vector2:
	return Vector2(cell.x * m.CELL + m.CELL * 0.5, cell.y * m.CELL + m.CELL * 0.5)

func _click(m: Node2D, cell: Vector2i, button: int, shift: bool = false) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.shift_pressed = shift
	e.position = _centre_of(m, cell)
	m._input(e)

func _key(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

func _wall(m: Node2D, cell: Vector2i) -> void:
	m._walls[cell.y][cell.x] = true

func _test_it_opens_with_a_path() -> void:
	print("the opening board")
	var m := _make()
	expect(m._walls.size() == m.ROWS and m._walls[0].size() == m.COLS, "the grid is the stated size")
	expect(m._path.size() > 0, "and a route is already worked out")
	expect(m._start != m._goal, "between two different cells")

func _test_the_path_is_a_walk_from_start_to_goal() -> void:
	print("path shape")
	var m := _make()
	expect(m._path[0] == m._start, "the path begins at the start")
	expect(m._path[m._path.size() - 1] == m._goal, "and ends at the goal")
	var contiguous := true
	for i in m._path.size() - 1:
		var step: Vector2i = m._path[i + 1] - m._path[i]
		if absi(step.x) + absi(step.y) != 1:
			contiguous = false
	expect(contiguous, "with every step one cell — no diagonals, no jumps")

func _test_an_open_grid_gives_the_shortest_route() -> void:
	print("optimality")
	var m := _make()
	# Nothing in the way, so the route can only be the Manhattan distance.
	# Anything longer means A* settled for a route it should have improved on.
	var expected: int = absi(m._goal.x - m._start.x) + absi(m._goal.y - m._start.y) + 1
	expect(m._path.size() == expected, "the route is as short as the grid allows (%d cells)" % expected)

func _test_the_heuristic_is_the_manhattan_distance() -> void:
	print("the heuristic")
	var m := _make()
	expect(m._heuristic(Vector2i(0, 0), Vector2i(3, 4)) == 7, "three across and four down is seven")
	expect(m._heuristic(Vector2i(3, 4), Vector2i(0, 0)) == 7, "and the same measured backwards")
	expect(m._heuristic(Vector2i(5, 5), Vector2i(5, 5)) == 0, "a cell is no distance from itself")
	# Never overestimating is what keeps A* optimal.
	expect(m._heuristic(Vector2i(0, 0), Vector2i(1, 1)) <= 2, "and it never claims more than the walk costs")

func _test_neighbours_are_the_four_open_cells_around_a_cell() -> void:
	print("neighbours")
	var m := _make()
	var middle := Vector2i(10, 7)
	expect(m._get_neighbors(middle).size() == 4, "a cell in open ground has four neighbours")
	expect(m._get_neighbors(Vector2i(0, 0)).size() == 2, "a corner has two")

	_wall(m, middle + Vector2i(1, 0))
	expect(m._get_neighbors(middle).size() == 3, "and a wall takes one away")
	for n in m._get_neighbors(middle):
		expect(m._heuristic(n, middle) == 1, "every neighbour is one step away")

func _test_a_wall_makes_the_route_longer() -> void:
	print("routing round")
	var m := _make()
	var direct: int = m._path.size()
	# A barrier across the middle with a gap near the top.
	for r in range(3, m.ROWS):
		_wall(m, Vector2i(10, r))
	m._run_astar()
	expect(m._path.size() > direct, "a wall in the way lengthens the route")
	expect(m._path.has(Vector2i(10, 2)), "which has to go through the gap")

func _test_a_walled_off_goal_has_no_path() -> void:
	print("no route")
	var m := _make()
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		_wall(m, m._goal + d)
	m._run_astar()
	expect(m._path.is_empty(), "a goal walled in on every side is unreachable")

func _test_the_path_never_stands_on_a_wall() -> void:
	print("walls hold")
	var m := _make()
	for r in range(0, m.ROWS - 2):
		_wall(m, Vector2i(8, r))
	for r in range(4, m.ROWS):
		_wall(m, Vector2i(13, r))
	m._run_astar()
	expect(m._path.size() > 0, "there is still a way through")
	var clear := true
	for cell: Vector2i in m._path:
		if m._walls[cell.y][cell.x]:
			clear = false
	expect(clear, "and no step of it stands on a wall")

func _test_the_search_does_not_explore_the_whole_grid() -> void:
	print("the point of the heuristic")
	var m := _make()
	# A breadth-first search would flood the grid; the heuristic is what keeps
	# the search pointed at the goal.
	# On an open grid a goal-directed search should touch a fraction of the
	# board. Half is a generous bound and still well under what a search with a
	# broken cost function explores.
	expect(m._closed_set.size() < m.ROWS * m.COLS / 2,
		"the search closes far fewer cells than the grid holds (%d of %d)" %
		[m._closed_set.size(), m.ROWS * m.COLS])

func _test_clicking_toggles_a_wall() -> void:
	print("drawing walls")
	var m := _make()
	var cell := Vector2i(5, 3)
	_click(m, cell, MOUSE_BUTTON_LEFT)
	expect(m._walls[cell.y][cell.x], "left-click puts a wall down")
	_click(m, cell, MOUSE_BUTTON_LEFT)
	expect(not m._walls[cell.y][cell.x], "and clicking it again takes it away")

func _test_the_start_and_goal_cannot_be_walled_over() -> void:
	print("protecting the ends")
	var m := _make()
	_click(m, m._start, MOUSE_BUTTON_LEFT)
	expect(not m._walls[m._start.y][m._start.x], "the start cannot be walled over")
	_click(m, m._goal, MOUSE_BUTTON_LEFT)
	expect(not m._walls[m._goal.y][m._goal.x], "nor the goal")

	# Dropping an end onto an existing wall clears it, or the search would
	# start from inside a wall.
	var cell := Vector2i(6, 9)
	_wall(m, cell)
	_click(m, cell, MOUSE_BUTTON_RIGHT)
	expect(m._start == cell, "right-click moves the start")
	expect(not m._walls[cell.y][cell.x], "and clears the wall it landed on")

func _test_the_start_and_goal_cannot_be_put_on_each_other() -> void:
	print("keeping them apart")
	var m := _make()
	var goal: Vector2i = m._goal
	_click(m, goal, MOUSE_BUTTON_RIGHT)
	expect(m._start != goal, "the start cannot be dropped onto the goal")

	var start: Vector2i = m._start
	_click(m, start, MOUSE_BUTTON_MIDDLE)
	expect(m._goal != start, "nor the goal onto the start")

func _test_moving_an_end_repaths() -> void:
	print("repathing")
	var m := _make()
	var before: Array = m._path.duplicate()
	_click(m, Vector2i(3, 2), MOUSE_BUTTON_RIGHT)
	expect(m._path != before, "moving the start works out a new route straight away")
	expect(m._path[0] == m._start, "from where the start now is")

func _test_tab_cycles_the_placement_mode() -> void:
	print("placement mode")
	var m := _make()
	var seen := {m._place_mode: true}
	for i in 3:
		_key(m, KEY_TAB)
		seen[m._place_mode] = true
	expect(seen.size() == 3, "tab cycles through the three modes")
	expect(m._place_mode == 0, "and comes back round to the first")

func _test_c_clears_the_walls() -> void:
	print("clearing")
	var m := _make()
	for r in range(3, 12):
		_wall(m, Vector2i(9, r))
	m._run_astar()
	_key(m, KEY_C)
	var any_wall := false
	for row in m._walls:
		for wall in row:
			if wall:
				any_wall = true
	expect(not any_wall, "C wipes every wall")
	expect(m._path.size() > 0, "and the route is worked out again on the cleared grid")

func _test_shift_click_moves_the_goal() -> void:
	print("shift-click")
	var m := _make()
	var cell := Vector2i(4, 11)
	_wall(m, cell)
	_click(m, cell, MOUSE_BUTTON_LEFT, true)
	expect(m._goal == cell, "shift-click moves the goal rather than drawing a wall")
	expect(not m._walls[cell.y][cell.x], "clearing the wall it landed on")
	expect(m._path[m._path.size() - 1] == cell, "and the route is worked out to the new goal")

	var onto_start := _make()
	_click(onto_start, onto_start._start, MOUSE_BUTTON_LEFT, true)
	expect(onto_start._goal != onto_start._start, "but it cannot be dropped onto the start")

func _test_the_placement_modes_place_what_they_say() -> void:
	print("the modes")
	var start_mode := _make()
	_key(start_mode, KEY_TAB)          # mode 1: place start
	var cell := Vector2i(7, 12)
	_wall(start_mode, cell)
	_click(start_mode, cell, MOUSE_BUTTON_LEFT)
	expect(start_mode._start == cell, "in start mode a click moves the start")
	expect(not start_mode._walls[cell.y][cell.x], "and clears the wall under it")

	var goal_mode := _make()
	_key(goal_mode, KEY_TAB)
	_key(goal_mode, KEY_TAB)           # mode 2: place goal
	var other := Vector2i(12, 3)
	_wall(goal_mode, other)
	_click(goal_mode, other, MOUSE_BUTTON_LEFT)
	expect(goal_mode._goal == other, "in goal mode it moves the goal")
	expect(not goal_mode._walls[other.y][other.x], "and clears that wall too")
	expect(goal_mode._path[goal_mode._path.size() - 1] == other, "with a route to it")

func _test_r_scatters_walls_without_burying_the_ends() -> void:
	print("random walls")
	var m := _make()
	_key(m, KEY_R)
	var walls := 0
	for row in m._walls:
		for wall in row:
			if wall:
				walls += 1
	expect(walls > 0, "R scatters walls across the grid (%d of them)" % walls)
	expect(walls < m.ROWS * m.COLS, "but not over every cell")
	expect(not m._walls[m._start.y][m._start.x], "the start is left clear")
	expect(not m._walls[m._goal.y][m._goal.x], "and so is the goal")
