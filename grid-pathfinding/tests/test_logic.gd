extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_path_found_on_open_grid()
	test_no_path_when_blocked()
	test_path_avoids_walls()
	test_manhattan_heuristic()
	test_path_starts_at_start()
	test_path_ends_at_goal()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[grid-pathfinding] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const COLS := 5
const ROWS := 5

func _make_grid(walls: Array = []) -> Array:
	var grid: Array = []
	for y in ROWS:
		var row := []
		for x in COLS: row.append(true)
		grid.append(row)
	for w in walls:
		grid[w.y][w.x] = false
	return grid

func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _valid(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < COLS and c.y >= 0 and c.y < ROWS

func _neighbors(grid: Array, c: Vector2i) -> Array:
	var result := []
	for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nb := c + d
		if _valid(nb) and grid[nb.y][nb.x]:
			result.append(nb)
	return result

func _astar(grid: Array, start: Vector2i, goal: Vector2i) -> Array:
	var open := [{"pos": start, "f": _heuristic(start, goal)}]
	var came_from := {}
	var g_score := {start: 0}
	while open.size() > 0:
		var bi := 0
		for i in open.size():
			if open[i]["f"] < open[bi]["f"]: bi = i
		var cur: Vector2i = open[bi]["pos"]
		open.remove_at(bi)
		if cur == goal:
			var path := [cur]
			while came_from.has(cur):
				cur = came_from[cur]
				path.push_front(cur)
			return path
		for nb in _neighbors(grid, cur):
			var tg: int = g_score.get(cur, 999) + 1
			if tg < g_score.get(nb, 999):
				came_from[nb] = cur; g_score[nb] = tg
				var found := false
				for n in open:
					if n["pos"] == nb: found = true; break
				if not found:
					open.append({"pos": nb, "f": tg + _heuristic(nb, goal)})
	return []

func test_path_found_on_open_grid() -> void:
	var path := _astar(_make_grid(), Vector2i(0,0), Vector2i(4,4))
	expect(path.size() > 0, "path found on open 5x5 grid")

func test_no_path_when_blocked() -> void:
	var walls := [Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1)]
	var path  := _astar(_make_grid(walls), Vector2i(2,0), Vector2i(2,4))
	expect(path.size() == 0, "no path when row is fully blocked")

func test_path_avoids_walls() -> void:
	var walls := [Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)]
	var path  := _astar(_make_grid(walls), Vector2i(0,0), Vector2i(4,0))
	for p in path:
		expect(not (p.x == 1 and p.y <= 2), "path does not pass through wall cell")

func test_manhattan_heuristic() -> void:
	expect(_heuristic(Vector2i(0,0), Vector2i(3,4)) == 7, "Manhattan h(0,0→3,4) = 7")

func test_path_starts_at_start() -> void:
	var path := _astar(_make_grid(), Vector2i(0,0), Vector2i(4,4))
	expect(path.size() > 0 and path[0] == Vector2i(0,0), "path starts at start cell")

func test_path_ends_at_goal() -> void:
	var path := _astar(_make_grid(), Vector2i(0,0), Vector2i(4,4))
	expect(path.size() > 0 and path[-1] == Vector2i(4,4), "path ends at goal cell")
