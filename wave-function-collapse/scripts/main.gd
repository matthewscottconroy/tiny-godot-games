extends Node2D

const GRID_W    := 40
const GRID_H    := 30
const CELL      := 16
const NUM_TILES := 4

# Tile indices: 0=DEEP, 1=SHALLOW, 2=SAND, 3=GRASS
const RULES := {
	0: [0, 1],
	1: [0, 1, 2],
	2: [1, 2, 3],
	3: [2, 3],
}
const WEIGHTS    := [1.0, 2.0, 2.0, 3.0]
const TILE_COLORS := [
	Color(0.08, 0.18, 0.50),
	Color(0.25, 0.48, 0.78),
	Color(0.88, 0.82, 0.48),
	Color(0.25, 0.55, 0.20),
]
const TILE_NAMES := ["Deep", "Shallow", "Sand", "Grass"]

var _collapsed: Array = []
var _cells: Array = []

func _ready() -> void:
	_generate()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_generate()

func _generate() -> void:
	for _attempt in 100:
		_reset()
		if _run():
			break
	queue_redraw()

func _reset() -> void:
	_collapsed.clear()
	_cells.clear()
	for y in GRID_H:
		var row_col: Array = []
		var row_cel: Array = []
		for _x in GRID_W:
			row_col.append(-1)
			var poss: Array = []
			poss.resize(NUM_TILES)
			poss.fill(true)
			row_cel.append(poss)
		_collapsed.append(row_col)
		_cells.append(row_cel)

func _run() -> bool:
	for _i in GRID_W * GRID_H:
		var pos := _min_entropy_cell()
		if pos.x == -1:
			return true
		var tile := _weighted_choice(_cells[pos.y][pos.x])
		_collapsed[pos.y][pos.x] = tile
		for t in NUM_TILES:
			_cells[pos.y][pos.x][t] = (t == tile)
		if not _propagate([pos]):
			return false
	return true

func _min_entropy_cell() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_e := NUM_TILES + 1
	for y in GRID_H:
		for x in GRID_W:
			if _collapsed[y][x] != -1:
				continue
			var e := _count(_cells[y][x])
			if e == 0:
				return Vector2i(-2, -2)
			if e < best_e:
				best_e = e
				best = Vector2i(x, y)
	return best

func _propagate(queue: Array) -> bool:
	var visited: Dictionary = {}
	for p in queue:
		visited[p] = true
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		visited.erase(pos)
		var cell: Array = _cells[pos.y][pos.x]
		for dir in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nx := pos.x + dir.x
			var ny := pos.y + dir.y
			if nx < 0 or nx >= GRID_W or ny < 0 or ny >= GRID_H:
				continue
			if _collapsed[ny][nx] != -1:
				continue
			var nb: Array = _cells[ny][nx]
			var changed := false
			for tile in NUM_TILES:
				if not nb[tile]:
					continue
				var ok := false
				for my_tile in NUM_TILES:
					if cell[my_tile] and tile in RULES[my_tile]:
						ok = true
						break
				if not ok:
					nb[tile] = false
					changed = true
			if changed:
				if _count(nb) == 0:
					return false
				var nbp := Vector2i(nx, ny)
				if not visited.has(nbp):
					queue.append(nbp)
					visited[nbp] = true
	return true

func _count(arr: Array) -> int:
	var n := 0
	for v in arr:
		if v: n += 1
	return n

func _weighted_choice(possible: Array) -> int:
	var total := 0.0
	for t in NUM_TILES:
		if possible[t]: total += WEIGHTS[t]
	var r := randf() * total
	var acc := 0.0
	for t in NUM_TILES:
		if possible[t]:
			acc += WEIGHTS[t]
			if acc >= r: return t
	return 0

func _draw() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var tile := _collapsed[y][x]
			var col := TILE_COLORS[tile] if tile >= 0 else Color(0.3, 0.3, 0.3)
			draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), col)
