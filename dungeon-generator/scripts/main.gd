extends Node2D

const MAP_W    := 80
const MAP_H    := 56
const CELL     := 8
const OFFSET   := Vector2(0.0, 24.0)
const NUM_ROOMS := 14
const MIN_W    := 5
const MAX_W    := 14
const MIN_H    := 4
const MAX_H    := 10

enum Tile { WALL, FLOOR, CORRIDOR }

var _grid: Array = []
var _rooms: Array[Rect2i] = []

func _ready() -> void:
	generate()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			generate()

func generate() -> void:
	_grid.clear()
	_rooms.clear()
	for _y in MAP_H:
		var row: Array = []
		row.resize(MAP_W)
		row.fill(Tile.WALL)
		_grid.append(row)

	for _i in NUM_ROOMS:
		_try_place_room()

	_rooms.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
		return a.position.x < b.position.x)

	for i in range(1, _rooms.size()):
		_connect(_rooms[i - 1], _rooms[i])

	queue_redraw()

func _try_place_room() -> void:
	for _attempt in 40:
		var w  := randi_range(MIN_W, MAX_W)
		var h  := randi_range(MIN_H, MAX_H)
		var rx := randi_range(1, MAP_W - w - 1)
		var ry := randi_range(1, MAP_H - h - 1)
		var r  := Rect2i(rx, ry, w, h)
		if not _overlaps(r):
			_rooms.append(r)
			_carve_room(r)
			return

func _overlaps(r: Rect2i) -> bool:
	var padded := r.grow(1)
	for existing in _rooms:
		if padded.intersects(existing):
			return true
	return false

func _carve_room(r: Rect2i) -> void:
	for cy in range(r.position.y, r.position.y + r.size.y):
		for cx in range(r.position.x, r.position.x + r.size.x):
			_grid[cy][cx] = Tile.FLOOR

func _connect(a: Rect2i, b: Rect2i) -> void:
	var ax := a.position.x + a.size.x / 2
	var ay := a.position.y + a.size.y / 2
	var bx := b.position.x + b.size.x / 2
	var by := b.position.y + b.size.y / 2
	var cx := ax
	while cx != bx:
		_grid[ay][cx] = Tile.CORRIDOR
		cx += 1 if bx > cx else -1
	var cy := ay
	while cy != by:
		_grid[cy][bx] = Tile.CORRIDOR
		cy += 1 if by > cy else -1

func _draw() -> void:
	var colors := [
		Color(0.08, 0.08, 0.10),   # WALL
		Color(0.68, 0.62, 0.52),   # FLOOR
		Color(0.48, 0.44, 0.36),   # CORRIDOR
	]
	for y in MAP_H:
		for x in MAP_W:
			var tile: int = _grid[y][x]
			draw_rect(Rect2(OFFSET + Vector2(x, y) * CELL, Vector2(CELL, CELL)), colors[tile])
	for r in _rooms:
		draw_rect(Rect2(OFFSET + Vector2(r.position) * CELL, Vector2(r.size) * CELL),
			Color(1, 1, 1, 0.06), false, 1.0)
