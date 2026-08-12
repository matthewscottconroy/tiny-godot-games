extends Node

# Standalone A* implementation for testing (no scene dependency)

const COLS := 20
const ROWS := 15

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_straight_path()
	_test_wall_avoidance()
	_test_no_path()
	_test_heuristic()
	_test_start_equals_goal()
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

# ──────────────────────── Standalone A* ────────────────────────

func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _get_neighbors(cell: Vector2i, walls: Array) -> Array:
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var result := []
	for d in dirs:
		var n: Vector2i = cell + d
		if n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < ROWS:
			if not walls[n.y][n.x]:
				result.append(n)
	return result

func _run_astar(start: Vector2i, goal: Vector2i, walls: Array) -> Array:
	if start == goal:
		return [start]

	var open_list: Array = [start]
	var closed_dict: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}

	g_score[start] = 0
	f_score[start] = _heuristic(start, goal)

	while open_list.size() > 0:
		var current = open_list[0]
		for node in open_list:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node

		if current == goal:
			var path := []
			var node = current
			while came_from.has(node):
				path.push_front(node)
				node = came_from[node]
			path.push_front(start)
			return path

		open_list.erase(current)
		closed_dict[current] = true

		for neighbor in _get_neighbors(current, walls):
			if closed_dict.has(neighbor):
				continue
			var tg: float = g_score.get(current, INF) + 1.0
			if tg < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tg
				f_score[neighbor] = tg + _heuristic(neighbor, goal)
				if not neighbor in open_list:
					open_list.append(neighbor)

	return []

func _make_walls(rows: int = ROWS, cols: int = COLS) -> Array:
	var walls := []
	for r in range(rows):
		var row := []
		row.resize(cols)
		for c in range(cols):
			row[c] = false
		walls.append(row)
	return walls

# ──────────────────────── Tests ────────────────────────

func _test_straight_path() -> void:
	print("Test: straight path (0,0) -> (4,0)")
	var walls := _make_walls()
	var path := _run_astar(Vector2i(0,0), Vector2i(4,0), walls)
	expect(path.size() == 5, "path length == 5 (got %d)" % path.size())

func _test_wall_avoidance() -> void:
	print("Test: wall avoidance")
	var walls := _make_walls()
	# Place a vertical wall at x=2, blocking y=0
	walls[0][2] = true
	var path := _run_astar(Vector2i(0,0), Vector2i(4,0), walls)
	expect(path.size() > 0, "path found despite wall")
	var passes_wall := false
	for p in path:
		if p == Vector2i(2, 0):
			passes_wall = true
	expect(not passes_wall, "path does not pass through wall at (2,0)")

func _test_no_path() -> void:
	print("Test: no path (goal surrounded by walls)")
	var walls := _make_walls()
	# Surround goal at (5,5) with walls
	walls[4][5] = true
	walls[6][5] = true
	walls[5][4] = true
	walls[5][6] = true
	var path := _run_astar(Vector2i(0,0), Vector2i(5,5), walls)
	expect(path.size() == 0, "no path found (got size %d)" % path.size())

func _test_heuristic() -> void:
	print("Test: Manhattan heuristic (0,0) -> (3,4) = 7")
	var h := _heuristic(Vector2i(0,0), Vector2i(3,4))
	expect(h == 7, "heuristic == 7 (got %d)" % h)

func _test_start_equals_goal() -> void:
	print("Test: start == goal")
	var walls := _make_walls()
	var path := _run_astar(Vector2i(3,3), Vector2i(3,3), walls)
	expect(path.size() == 1, "path has one node (got %d)" % path.size())
	expect(path.size() == 1 and path[0] == Vector2i(3,3), "path[0] is start/goal")
