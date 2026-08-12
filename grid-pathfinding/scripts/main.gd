extends Node2D

const COLS      := 20
const ROWS      := 14
const CELL      := 30
const OFFSET_X  := 10
const OFFSET_Y  := 35

var _grid:   Array = []  # Array[Array[bool]]
var _start:  Vector2i = Vector2i(-1, -1)
var _goal:   Vector2i = Vector2i(-1, -1)
var _path:   Array    = []  # Array[Vector2i]
var _state:  int      = 0   # 0=set_start 1=set_goal 2=done

@onready var _hint: Label = $HintLabel

func _ready() -> void:
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			row.append(true)
		_grid.append(row)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var cell := _screen_to_cell(event.position)
		if not _valid(cell):
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			match _state:
				0:
					_start = cell
					_state = 1
					_hint.text = "Right-click to set goal"
				1:
					_goal = cell
					_state = 2
					_path  = _astar()
					_hint.text = "Left-click to reset"
				2:
					_start = Vector2i(-1, -1)
					_goal  = Vector2i(-1, -1)
					_path  = []
					_state = 0
					_hint.text = "Left-click to set start"
		elif event.button_index == MOUSE_BUTTON_RIGHT and _state != 2:
			_grid[cell.y][cell.x] = not _grid[cell.y][cell.x]
			if _state == 2:
				_path = _astar()
		queue_redraw()

func _screen_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int((pos.x - OFFSET_X) / CELL), int((pos.y - OFFSET_Y) / CELL))

func _valid(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < COLS and c.y >= 0 and c.y < ROWS

func _astar() -> Array:
	if not _valid(_start) or not _valid(_goal):
		return []
	var open:       Array = [{"pos": _start, "f": _heuristic(_start)}]
	var came_from:  Dictionary = {}
	var g_score:    Dictionary = {_start: 0}

	while open.size() > 0:
		var bi := 0
		for i in open.size():
			if open[i]["f"] < open[bi]["f"]:
				bi = i
		var cur: Vector2i = open[bi]["pos"]
		open.remove_at(bi)
		if cur == _goal:
			return _reconstruct(came_from, cur)
		for nb in _neighbors(cur):
			var tg: int = g_score.get(cur, 999999) + 1
			if tg < g_score.get(nb, 999999):
				came_from[nb] = cur
				g_score[nb]   = tg
				var ff := tg + _heuristic(nb)
				var found := false
				for n in open:
					if n["pos"] == nb:
						found = true; break
				if not found:
					open.append({"pos": nb, "f": ff})
	return []

func _heuristic(c: Vector2i) -> int:
	return absi(c.x - _goal.x) + absi(c.y - _goal.y)

func _neighbors(c: Vector2i) -> Array:
	var result := []
	for d: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nb := c + d
		if _valid(nb) and _grid[nb.y][nb.x]:
			result.append(nb)
	return result

func _reconstruct(came_from: Dictionary, cur: Vector2i) -> Array:
	var path := [cur]
	while came_from.has(cur):
		cur = came_from[cur]
		path.push_front(cur)
	return path

func _draw() -> void:
	for y in ROWS:
		for x in COLS:
			var rx := OFFSET_X + x * CELL
			var ry := OFFSET_Y + y * CELL
			var col := Color(0.18, 0.18, 0.22) if _grid[y][x] else Color(0.45, 0.28, 0.18)
			draw_rect(Rect2(rx + 1, ry + 1, CELL - 2, CELL - 2), col)

	for p in _path:
		var rx: float = OFFSET_X + p.x * CELL
		var ry: float = OFFSET_Y + p.y * CELL
		draw_rect(Rect2(rx + 3, ry + 3, CELL - 6, CELL - 6), Color(1.0, 0.85, 0.1, 0.8))

	if _valid(_start):
		var rx := OFFSET_X + _start.x * CELL
		var ry := OFFSET_Y + _start.y * CELL
		draw_circle(Vector2(rx + CELL/2, ry + CELL/2), CELL/2 - 4, Color(0.2, 0.9, 0.3))
	if _valid(_goal):
		var rx := OFFSET_X + _goal.x * CELL
		var ry := OFFSET_Y + _goal.y * CELL
		draw_circle(Vector2(rx + CELL/2, ry + CELL/2), CELL/2 - 4, Color(0.9, 0.2, 0.2))
