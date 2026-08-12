extends Node2D

const GRID_W := 80
const GRID_H := 60
const CELL   := 8

enum Cell { EMPTY = 0, SAND = 1, WATER = 2, STONE = 3 }

const COLORS := [
	Color(0.08, 0.08, 0.10),   # EMPTY
	Color(0.88, 0.80, 0.35),   # SAND
	Color(0.25, 0.50, 0.90),   # WATER
	Color(0.50, 0.48, 0.46),   # STONE
]

var _grid: Array = []
var _selected: int = Cell.SAND
var _scan_right := true
var _brush := 3

func _ready() -> void:
	_reset()

func _reset() -> void:
	_grid.clear()
	for _y in GRID_H:
		var row: Array = []
		row.resize(GRID_W)
		row.fill(Cell.EMPTY)
		_grid.append(row)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _selected = Cell.SAND
			KEY_2: _selected = Cell.WATER
			KEY_3: _selected = Cell.STONE
			KEY_C: _reset()

func _process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_paint(get_viewport().get_mouse_position(), _selected)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_paint(get_viewport().get_mouse_position(), Cell.EMPTY)
	_step()
	queue_redraw()

func _paint(mouse: Vector2, mat: int) -> void:
	var cx := int(mouse.x / CELL)
	var cy := int(mouse.y / CELL)
	for dy in range(-_brush, _brush + 1):
		for dx in range(-_brush, _brush + 1):
			var gx := cx + dx
			var gy := cy + dy
			if gx >= 0 and gx < GRID_W and gy >= 0 and gy < GRID_H:
				_grid[gy][gx] = mat

func _step() -> void:
	_scan_right = not _scan_right
	for y in range(GRID_H - 2, -1, -1):
		if _scan_right:
			for x in GRID_W:
				_update(x, y)
		else:
			for x in range(GRID_W - 1, -1, -1):
				_update(x, y)

func _update(x: int, y: int) -> void:
	var cell: int = _grid[y][x]
	if cell == Cell.EMPTY or cell == Cell.STONE:
		return
	match cell:
		Cell.SAND:
			if _grid[y + 1][x] == Cell.EMPTY:
				_move(x, y, x, y + 1)
			else:
				var dl: bool = x > 0 and _grid[y + 1][x - 1] == Cell.EMPTY
				var dr: bool = x < GRID_W - 1 and _grid[y + 1][x + 1] == Cell.EMPTY
				if dl and dr:
					var dx := -1 if randf() < 0.5 else 1
					_move(x, y, x + dx, y + 1)
				elif dl:
					_move(x, y, x - 1, y + 1)
				elif dr:
					_move(x, y, x + 1, y + 1)
		Cell.WATER:
			if _grid[y + 1][x] == Cell.EMPTY:
				_move(x, y, x, y + 1)
			else:
				var dl: bool = x > 0 and _grid[y][x - 1] == Cell.EMPTY
				var dr: bool = x < GRID_W - 1 and _grid[y][x + 1] == Cell.EMPTY
				if dl and dr:
					var dx := -1 if randf() < 0.5 else 1
					_move(x, y, x + dx, y)
				elif dl:
					_move(x, y, x - 1, y)
				elif dr:
					_move(x, y, x + 1, y)

func _move(fx: int, fy: int, tx: int, ty: int) -> void:
	_grid[ty][tx] = _grid[fy][fx]
	_grid[fy][fx] = Cell.EMPTY

func _draw() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var mat: int = _grid[y][x]
			if mat != Cell.EMPTY:
				draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), COLORS[mat])
