extends Node2D

const GRID_W    := 64
const GRID_H    := 48
const CELL      := 10
const THRESHOLD := 0.5

var _field: Array = []

func _ready() -> void:
	_regenerate()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_regenerate()

func _regenerate() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	_field.clear()
	for y in GRID_H:
		var row: Array = []
		for x in GRID_W:
			row.append((noise.get_noise_2d(x, y) + 1.0) * 0.5)
		_field.append(row)
	queue_redraw()

func _draw() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var v: float = _field[y][x]
			var col := Color(v * 0.25, v * 0.45, v * 0.70)
			draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), col)

	for y in range(GRID_H - 1):
		for x in range(GRID_W - 1):
			_draw_contour(x, y)

func _draw_contour(cx: int, cy: int) -> void:
	var tl: float = _field[cy][cx]
	var tr: float = _field[cy][cx + 1]
	var br: float = _field[cy + 1][cx + 1]
	var bl: float = _field[cy + 1][cx]

	var idx := (
		(1 if tl >= THRESHOLD else 0) |
		(2 if tr >= THRESHOLD else 0) |
		(4 if br >= THRESHOLD else 0) |
		(8 if bl >= THRESHOLD else 0)
	)
	if idx == 0 or idx == 15:
		return

	var top    := Vector2((cx + _t(tl, tr)) * CELL, cy * CELL)
	var right  := Vector2((cx + 1) * CELL,           (cy + _t(tr, br)) * CELL)
	var bottom := Vector2((cx + _t(bl, br)) * CELL,  (cy + 1) * CELL)
	var left   := Vector2(cx * CELL,                  (cy + _t(tl, bl)) * CELL)
	var col    := Color(1.0, 1.0, 1.0, 0.9)

	match idx:
		1, 14: draw_line(left, top, col, 1.5)
		2, 13: draw_line(top, right, col, 1.5)
		3, 12: draw_line(left, right, col, 1.5)
		4, 11: draw_line(right, bottom, col, 1.5)
		5:
			draw_line(left, top, col, 1.5)
			draw_line(right, bottom, col, 1.5)
		6, 9:  draw_line(top, bottom, col, 1.5)
		7, 8:  draw_line(left, bottom, col, 1.5)
		10:
			draw_line(top, right, col, 1.5)
			draw_line(bottom, left, col, 1.5)

func _t(a: float, b: float) -> float:
	if absf(b - a) < 0.00001:
		return 0.5
	return clampf((THRESHOLD - a) / (b - a), 0.0, 1.0)
