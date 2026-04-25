extends Node2D

const CELL  := 40
const COLS  := 16
const ROWS  := 12

var wall_set : Dictionary = {}

func _ready() -> void:
	var walls : Array[Vector2i] = []
	# Border
	for x in COLS:
		walls.append(Vector2i(x, 0))
		walls.append(Vector2i(x, ROWS - 1))
	for y in ROWS:
		walls.append(Vector2i(0, y))
		walls.append(Vector2i(COLS - 1, y))
	# Interior walls
	for w in [Vector2i(4,2),Vector2i(4,3),Vector2i(4,4),Vector2i(4,5),
			  Vector2i(8,3),Vector2i(8,4),Vector2i(8,5),Vector2i(8,6),Vector2i(8,7),
			  Vector2i(11,2),Vector2i(11,3),Vector2i(12,3),Vector2i(12,4),
			  Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
			  Vector2i(3,9),Vector2i(3,10),Vector2i(13,7),Vector2i(14,7)]:
		walls.append(w)
	for w in walls:
		wall_set[w] = true

func is_wall(cell: Vector2i) -> bool:
	return wall_set.has(cell)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)

func _draw() -> void:
	for x in COLS + 1:
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, ROWS * CELL), Color(1, 1, 1, 0.08), 1)
	for y in ROWS + 1:
		draw_line(Vector2(0, y * CELL), Vector2(COLS * CELL, y * CELL), Color(1, 1, 1, 0.08), 1)
	for cell in wall_set:
		draw_rect(Rect2(cell.x * CELL, cell.y * CELL, CELL, CELL), Color(0.35, 0.35, 0.4))
