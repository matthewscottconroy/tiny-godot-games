extends Node2D

const COLS := 20
const ROWS := 15
const CELL := 32

var _walls: Array[Array] = []
var _start: Vector2i = Vector2i(1, 7)
var _goal: Vector2i = Vector2i(18, 7)
var _path: Array[Vector2i] = []
var _open_set: Array[Vector2i] = []
var _closed_set: Array[Vector2i] = []
var _place_mode: int = 0  # 0=wall, 1=start, 2=goal

func _ready() -> void:
	_walls.resize(ROWS)
	for r in range(ROWS):
		var row: Array = []
		row.resize(COLS)
		for c in range(COLS):
			row[c] = false
		_walls[r] = row
	_run_astar()

func _cell_from_mouse(pos: Vector2) -> Vector2i:
	var c := int(pos.x / CELL)
	var r := int(pos.y / CELL)
	c = clampi(c, 0, COLS - 1)
	r = clampi(r, 0, ROWS - 1)
	return Vector2i(c, r)

func _input(event: InputEvent) -> void:
	var changed := false

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			var cell := _cell_from_mouse(mb.position)

			if mb.button_index == MOUSE_BUTTON_LEFT and mb.shift_pressed:
				# Shift+Left = set goal
				if cell != _start:
					_goal = cell
					_walls[cell.y][cell.x] = false
					changed = true
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				if _place_mode == 0:
					if cell != _start and cell != _goal:
						_walls[cell.y][cell.x] = not _walls[cell.y][cell.x]
						changed = true
				elif _place_mode == 1:
					if cell != _goal:
						_start = cell
						_walls[cell.y][cell.x] = false
						changed = true
				elif _place_mode == 2:
					if cell != _start:
						_goal = cell
						_walls[cell.y][cell.x] = false
						changed = true

			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				if cell != _goal:
					_start = cell
					_walls[cell.y][cell.x] = false
					changed = true

			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				if cell != _start:
					_goal = cell
					_walls[cell.y][cell.x] = false
					changed = true

	if event is InputEventKey:
		var kb := event as InputEventKey
		if kb.pressed and not kb.echo:
			if kb.keycode == KEY_TAB:
				_place_mode = (_place_mode + 1) % 3
				queue_redraw()
			elif kb.keycode == KEY_C:
				for r in range(ROWS):
					for c in range(COLS):
						_walls[r][c] = false
				changed = true
			elif kb.keycode == KEY_R:
				for r in range(ROWS):
					for c in range(COLS):
						var cell := Vector2i(c, r)
						if cell != _start and cell != _goal:
							_walls[r][c] = randf() < 0.30
						else:
							_walls[r][c] = false
				changed = true

	if changed:
		_run_astar()
		queue_redraw()

func _run_astar() -> void:
	_open_set.clear()
	_closed_set.clear()
	_path.clear()

	var open_list: Array[Vector2i] = [_start]
	var closed_set_dict: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}

	g_score[_start] = 0
	f_score[_start] = _heuristic(_start, _goal)

	while open_list.size() > 0:
		# Find node with lowest f_score
		var current := open_list[0]
		for node in open_list:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node

		if current == _goal:
			# Reconstruct path
			var node := current
			while came_from.has(node):
				_path.push_front(node)
				node = came_from[node]
			_path.push_front(_start)
			_closed_set.assign(closed_set_dict.keys())
			_open_set = open_list.duplicate()
			return

		open_list.erase(current)
		closed_set_dict[current] = true

		for neighbor in _get_neighbors(current):
			if closed_set_dict.has(neighbor):
				continue
			var tentative_g: float = g_score.get(current, INF) + 1.0
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, _goal)
				if not neighbor in open_list:
					open_list.append(neighbor)

	_closed_set.assign(closed_set_dict.keys())
	_open_set = open_list.duplicate()
	_path = []

func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	var result: Array[Vector2i] = []
	for d in dirs:
		var n := cell + d
		if n.x >= 0 and n.x < COLS and n.y >= 0 and n.y < ROWS:
			if not _walls[n.y][n.x]:
				result.append(n)
	return result

func _draw() -> void:
	# Build lookup sets for speed
	var path_set: Dictionary = {}
	for p in _path:
		path_set[p] = true
	var open_set_dict: Dictionary = {}
	for p in _open_set:
		open_set_dict[p] = true
	var closed_set_dict: Dictionary = {}
	for p in _closed_set:
		closed_set_dict[p] = true

	# Draw cells
	for r in range(ROWS):
		for c in range(COLS):
			var cell := Vector2i(c, r)
			var rect := Rect2(c * CELL, r * CELL, CELL, CELL)
			var col: Color

			if _walls[r][c]:
				col = Color(0.25, 0.25, 0.28)
			elif path_set.has(cell):
				col = Color(0.2, 0.85, 0.3)
			elif closed_set_dict.has(cell):
				col = Color(0.3, 0.5, 0.75, 0.55)
			elif open_set_dict.has(cell):
				col = Color(0.85, 0.82, 0.2, 0.55)
			else:
				col = Color(0.08, 0.08, 0.12)

			draw_rect(rect, col)

	# Draw grid lines
	var grid_col := Color(0.2, 0.2, 0.25, 0.5)
	for c in range(COLS + 1):
		draw_line(Vector2(c * CELL, 0), Vector2(c * CELL, ROWS * CELL), grid_col, 1.0)
	for r in range(ROWS + 1):
		draw_line(Vector2(0, r * CELL), Vector2(COLS * CELL, r * CELL), grid_col, 1.0)

	# Draw start and goal circles
	var start_center := Vector2(_start.x * CELL + CELL / 2, _start.y * CELL + CELL / 2)
	var goal_center := Vector2(_goal.x * CELL + CELL / 2, _goal.y * CELL + CELL / 2)
	draw_circle(start_center, CELL * 0.38, Color(0.1, 1.0, 0.2))
	draw_circle(goal_center, CELL * 0.38, Color(1.0, 0.15, 0.15))

	# Draw path as connected line
	if _path.size() >= 2:
		var pts: PackedVector2Array = []
		for p in _path:
			pts.append(Vector2(p.x * CELL + CELL / 2, p.y * CELL + CELL / 2))
		draw_polyline(pts, Color(0.1, 1.0, 0.3), 3.0)

	# UI overlay
	var mode_names := ["Wall", "Start", "Goal"]
	var mode_col := Color(1.0, 0.9, 0.3)
	draw_string(ThemeDB.fallback_font, Vector2(8, 20), "A* Pathfinding", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
	draw_string(ThemeDB.fallback_font, Vector2(8, 38), "Click Mode: %s" % mode_names[_place_mode], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, mode_col)

	var path_label := "Path: %d steps" % (_path.size() - 1) if _path.size() > 1 else ("Path: none" if _path.size() == 0 else "Path: start=goal")
	draw_string(ThemeDB.fallback_font, Vector2(8, 54), path_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 1.0, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(8, 70), "Open: %d  Closed: %d" % [_open_set.size(), _closed_set.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.7, 1.0))

	var hint := "LClick: wall  RClick: start  MClick/Shift: goal  Tab: mode  C: clear  R: random"
	draw_string(ThemeDB.fallback_font, Vector2(4, 475), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6))
