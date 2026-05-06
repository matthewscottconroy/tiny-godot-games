extends Node2D

const PLAYER_SPEED := 50.0
const WORLD_W := 160.0
const WORLD_H := 120.0
const TILE_SIZE := 8.0

var _player_pos: Vector2 = Vector2(80.0, 60.0)

# Obstacle rects in world space (160x120)
const OBSTACLES: Array = [
	{"rect": Rect2(20, 30, 12, 12), "color_idx": 0},
	{"rect": Rect2(60, 20, 10, 14), "color_idx": 1},
	{"rect": Rect2(110, 50, 14, 10), "color_idx": 2},
	{"rect": Rect2(40, 70, 16, 12), "color_idx": 3},
	{"rect": Rect2(90, 80, 12, 16), "color_idx": 4},
	{"rect": Rect2(130, 30, 10, 18), "color_idx": 5},
]

const OBSTACLE_COLORS: Array = [
	Color(0.8, 0.2, 0.2),
	Color(0.2, 0.6, 0.8),
	Color(0.8, 0.7, 0.2),
	Color(0.2, 0.8, 0.4),
	Color(0.7, 0.3, 0.8),
	Color(0.8, 0.5, 0.2),
]

func _process(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		move.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		move.y += 1.0

	if move != Vector2.ZERO:
		move = move.normalized()
	_player_pos += move * PLAYER_SPEED * delta

	# Wrap around world edges
	_player_pos.x = fposmod(_player_pos.x, WORLD_W)
	_player_pos.y = fposmod(_player_pos.y, WORLD_H)

	queue_redraw()

func _draw() -> void:
	# Checkerboard floor
	var cols: int = int(WORLD_W / TILE_SIZE)
	var rows: int = int(WORLD_H / TILE_SIZE)
	var color_a := Color(0.18, 0.22, 0.18)
	var color_b := Color(0.14, 0.17, 0.14)
	for row in range(rows):
		for col in range(cols):
			var c: Color = color_a if (col + row) % 2 == 0 else color_b
			draw_rect(Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE), c)

	# Obstacles
	for i in range(OBSTACLES.size()):
		var obs = OBSTACLES[i]
		draw_rect(obs["rect"], OBSTACLE_COLORS[obs["color_idx"]])
		# Dark border
		draw_rect(obs["rect"], Color(0.0, 0.0, 0.0, 0.5), false)

	# Player character (small pixel art-style figure)
	var px: float = _player_pos.x
	var py: float = _player_pos.y

	# Shadow
	draw_rect(Rect2(px - 3.0, py + 3.0, 6.0, 2.0), Color(0.0, 0.0, 0.0, 0.4))

	# Body
	draw_rect(Rect2(px - 2.0, py - 2.0, 4.0, 5.0), Color(0.2, 0.5, 0.9))

	# Head
	draw_rect(Rect2(px - 2.0, py - 5.0, 4.0, 3.0), Color(0.9, 0.75, 0.6))

	# Eyes
	draw_rect(Rect2(px - 1.0, py - 5.0, 1.0, 1.0), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(px + 1.0, py - 5.0, 1.0, 1.0), Color(0.1, 0.1, 0.1))

	# Legs
	draw_rect(Rect2(px - 2.0, py + 3.0, 2.0, 2.0), Color(0.15, 0.35, 0.6))
	draw_rect(Rect2(px + 0.0, py + 3.0, 2.0, 2.0), Color(0.15, 0.35, 0.6))

	# HUD (still in low-res world coords)
	draw_string(ThemeDB.fallback_font, Vector2(2, 8), "WASD/Arrows: move", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.9, 0.9, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(2, 15), "P: toggle pixel mode", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.9, 0.9, 0.9))
