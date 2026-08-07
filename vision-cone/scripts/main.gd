extends Node2D

const CONE_ANGLE := PI / 3.0   # 60-degree half-cone → 120-degree total FOV
const CONE_RANGE := 180.0
const ENEMY_SPEED := 80.0
const PLAYER_SPEED := 150.0

# Hardcoded wall obstacles (Rect2: position, size)
var _walls: Array[Rect2] = [
	Rect2(200, 100, 80, 20),
	Rect2(350, 180, 20, 90),
	Rect2(120, 320, 100, 20),
	Rect2(440, 280, 20, 80),
	Rect2(280, 370, 90, 20),
]

var _player_pos: Vector2 = Vector2(500, 350)
var _enemy_pos: Vector2 = Vector2(150, 240)
var _enemy_dir: float = 0.0        # angle in radians, facing right initially
var _enemy_patrol_target: float = 260.0  # x position to walk toward
var _detected: bool = false

# The reusable detector (scripts/vision_cone.gd) — all the "can the enemy see
# the player" geometry lives here; this file just moves things and draws.
var _vision := VisionCone.new(CONE_ANGLE, CONE_RANGE)

# Patrol x-positions the enemy toggles between
const _PATROL_LEFT := 80.0
const _PATROL_RIGHT := 260.0

func _process(delta: float) -> void:
	# --- Player movement (WASD / arrow keys) ---
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0

	if move.length_squared() > 0.0:
		move = move.normalized() * PLAYER_SPEED * delta
		var new_pos := _player_pos + move
		# Clamp to viewport
		new_pos.x = clampf(new_pos.x, 12.0, 628.0)
		new_pos.y = clampf(new_pos.y, 12.0, 468.0)
		# Simple AABB wall push-out
		if not _point_in_walls(new_pos):
			_player_pos = new_pos

	# --- Enemy patrol ---
	var dx := _enemy_patrol_target - _enemy_pos.x
	if absf(dx) < 2.0:
		# Flip target
		_enemy_patrol_target = _PATROL_LEFT if _enemy_patrol_target == _PATROL_RIGHT else _PATROL_RIGHT
	else:
		_enemy_pos.x += signf(dx) * ENEMY_SPEED * delta
		_enemy_dir = atan2(0.0, signf(dx))  # 0 = right, PI = left

	_detected = _vision.can_see(_enemy_pos, _enemy_dir, _player_pos, _walls)
	queue_redraw()


func _point_in_walls(p: Vector2) -> bool:
	for w in _walls:
		# Expand rect slightly for the player radius
		var expanded := Rect2(w.position - Vector2(12, 12), w.size + Vector2(24, 24))
		if expanded.has_point(p):
			return true
	return false


func _draw() -> void:
	# --- Walls ---
	for w in _walls:
		draw_rect(w, Color(0.4, 0.4, 0.4))
		draw_rect(w, Color(0.6, 0.6, 0.6), false, 1.5)

	# --- Vision cone (wedge polygon) ---
	var cone_color := Color(1.0, 0.3, 0.3, 0.3) if _detected else Color(1.0, 1.0, 0.0, 0.2)
	var cone_pts := PackedVector2Array()
	cone_pts.append(_enemy_pos)
	var arc_steps := 16
	for i in range(arc_steps + 1):
		var t := float(i) / float(arc_steps)
		var a := (_enemy_dir - CONE_ANGLE) + t * (CONE_ANGLE * 2.0)
		cone_pts.append(_enemy_pos + Vector2(cos(a), sin(a)) * CONE_RANGE)
	draw_polygon(cone_pts, PackedColorArray([cone_color]))

	# Cone outline
	var outline_color := Color(1.0, 0.5, 0.5, 0.6) if _detected else Color(1.0, 1.0, 0.0, 0.5)
	draw_line(_enemy_pos,
		_enemy_pos + Vector2(cos(_enemy_dir - CONE_ANGLE), sin(_enemy_dir - CONE_ANGLE)) * CONE_RANGE,
		outline_color, 1.0)
	draw_line(_enemy_pos,
		_enemy_pos + Vector2(cos(_enemy_dir + CONE_ANGLE), sin(_enemy_dir + CONE_ANGLE)) * CONE_RANGE,
		outline_color, 1.0)

	# --- Enemy ---
	var enemy_color := Color(0.9, 0.15, 0.15) if _detected else Color(0.8, 0.4, 0.1)
	draw_circle(_enemy_pos, 14.0, enemy_color)
	draw_circle(_enemy_pos, 14.0, Color(1, 1, 1, 0.3), false, 1.5)
	# Direction indicator
	var dir_end := _enemy_pos + Vector2(cos(_enemy_dir), sin(_enemy_dir)) * 20.0
	draw_line(_enemy_pos, dir_end, Color(1, 1, 1, 0.8), 2.5)

	# --- Player ---
	draw_circle(_player_pos, 12.0, Color(0.2, 0.5, 1.0))
	draw_circle(_player_pos, 12.0, Color(1, 1, 1, 0.5), false, 1.5)

	# --- Detected label ---
	if _detected:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(320, 245),
			"DETECTED!",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			28,
			Color(1.0, 0.1, 0.1)
		)

	# --- Title & hints ---
	draw_string(ThemeDB.fallback_font, Vector2(10, 22), "Vision Cone Demo",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(10, 460), "WASD / Arrow Keys: move player",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8, 0.7))
