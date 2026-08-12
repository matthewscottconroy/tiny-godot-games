extends Node2D

const SPEED := 180.0
const JUMP_VEL := -380.0
const GRAVITY := 700.0
const PLAYER_W := 20.0
const PLAYER_H := 36.0
const LEDGE_GRAB_RANGE := 8.0
const LEDGE_VERT_RANGE := 10.0

const PLATFORMS: Array = [
	# Rect2(x, y, w, h)
]

# Initialized in _ready so const arrays work in GDScript 4
var _platforms: Array = []

var _pos: Vector2 = Vector2(50.0, 400.0)
var _vel: Vector2 = Vector2.ZERO
var _on_floor: bool = false

enum PState { NORMAL, HANGING }
var _state: PState = PState.NORMAL
var _hang_pos: Vector2 = Vector2.ZERO
var _hang_edge: Vector2 = Vector2.ZERO

var _jump_pressed_last := false
var _down_pressed_last := false

func _ready() -> void:
	_platforms = [
		Rect2(0, 440, 640, 40),
		Rect2(80, 340, 140, 18),
		Rect2(300, 260, 140, 18),
		Rect2(460, 340, 140, 18),
		Rect2(160, 160, 140, 18),
	]

func _get_player_rect() -> Rect2:
	return Rect2(_pos.x - PLAYER_W * 0.5, _pos.y - PLAYER_H, PLAYER_W, PLAYER_H)

func _physics_process(delta: float) -> void:
	var jump_pressed := Input.is_action_pressed("ui_up")
	var down_pressed := Input.is_action_pressed("ui_down")
	var jump_just := jump_pressed and not _jump_pressed_last
	var down_just := down_pressed and not _down_pressed_last
	_jump_pressed_last = jump_pressed
	_down_pressed_last = down_pressed

	match _state:
		PState.NORMAL:
			_vel.y += GRAVITY * delta
			_vel.x = Input.get_axis("ui_left", "ui_right") * SPEED
			if _on_floor and jump_just:
				_vel.y = JUMP_VEL
			_pos += _vel * delta
			_on_floor = false
			_resolve_collisions()
			# Ledge grab check: only when falling
			if _vel.y > 0:
				_check_ledge_grab()

		PState.HANGING:
			_vel = Vector2.ZERO
			_pos.y = _hang_edge.y + PLAYER_H
			if _hang_edge.x <= _pos.x:
				_pos.x = _hang_edge.x + PLAYER_W * 0.5
			else:
				_pos.x = _hang_edge.x - PLAYER_W * 0.5
			_hang_pos = _pos

			if jump_just:
				# Pull up onto platform
				_pos.y = _hang_edge.y - 2.0
				_vel.y = -100.0
				_state = PState.NORMAL
			elif down_just:
				# Drop
				_vel.y = 100.0
				_state = PState.NORMAL

	queue_redraw()

func _resolve_collisions() -> void:
	_on_floor = false
	for plat in _platforms:
		var pr := _get_player_rect()
		if pr.intersects(plat):
			# Find least-overlap axis
			var overlap_x := minf(pr.end.x, plat.end.x) - maxf(pr.position.x, plat.position.x)
			var overlap_y := minf(pr.end.y, plat.end.y) - maxf(pr.position.y, plat.position.y)
			if overlap_x < overlap_y:
				# Push horizontally
				var center_x := pr.position.x + pr.size.x * 0.5
				var plat_center_x: float = plat.position.x + plat.size.x * 0.5
				if center_x < plat_center_x:
					_pos.x -= overlap_x
				else:
					_pos.x += overlap_x
				_vel.x = 0.0
			else:
				# Push vertically
				var center_y := pr.position.y + pr.size.y * 0.5
				var plat_center_y: float = plat.position.y + plat.size.y * 0.5
				if center_y < plat_center_y:
					# Player is above: land on top
					_pos.y -= overlap_y
					if _vel.y > 0:
						_vel.y = 0.0
					_on_floor = true
				else:
					_pos.y += overlap_y
					if _vel.y < 0:
						_vel.y = 0.0

	# Keep player in screen
	_pos.x = clampf(_pos.x, PLAYER_W * 0.5, 640.0 - PLAYER_W * 0.5)
	if _pos.y > 480.0:
		_pos.y = 480.0

func _check_ledge_grab() -> void:
	var player_top := _pos.y - PLAYER_H
	for plat in _platforms:
		var plat_top: float = plat.position.y
		# Check vertical proximity: player top near platform top
		if absf(player_top - plat_top) > LEDGE_VERT_RANGE:
			continue
		# Check left ledge corner
		var left_edge: float = plat.position.x
		if absf((_pos.x + PLAYER_W * 0.5) - left_edge) < LEDGE_GRAB_RANGE:
			_hang_edge = Vector2(left_edge, plat_top)
			_state = PState.HANGING
			return
		# Check right ledge corner
		var right_edge: float = plat.position.x + plat.size.x
		if absf((_pos.x - PLAYER_W * 0.5) - right_edge) < LEDGE_GRAB_RANGE:
			_hang_edge = Vector2(right_edge, plat_top)
			_state = PState.HANGING
			return

func _draw() -> void:
	# Draw platforms
	for plat in _platforms:
		draw_rect(plat, Color(0.42, 0.30, 0.18))
		draw_line(plat.position, Vector2(plat.end.x, plat.position.y), Color(0.75, 0.60, 0.40), 2.5)
		draw_rect(plat, Color(0.6, 0.48, 0.32), false, 1.0)

	# Draw ledge corners as yellow dots
	for plat in _platforms:
		draw_circle(Vector2(plat.position.x, plat.position.y), 4.5, Color(1.0, 0.9, 0.1, 0.7))
		draw_circle(Vector2(plat.end.x, plat.position.y), 4.5, Color(1.0, 0.9, 0.1, 0.7))

	# Draw player
	var body_rect := _get_player_rect()
	var body_color := Color(0.25, 0.55, 0.85) if _state == PState.NORMAL else Color(0.85, 0.55, 0.25)
	draw_rect(body_rect, body_color)
	draw_rect(body_rect, body_color.darkened(0.3), false, 1.5)
	# Head
	var head_center := Vector2(_pos.x, _pos.y - PLAYER_H - 10.0)
	draw_circle(head_center, 10.0, body_color)
	draw_arc(head_center, 10.0, 0, TAU, 24, body_color.darkened(0.3), 1.5)

	# Hanging: draw hand lines to ledge
	if _state == PState.HANGING:
		var top_left := Vector2(body_rect.position.x, body_rect.position.y)
		var top_right := Vector2(body_rect.end.x, body_rect.position.y)
		draw_line(top_left, _hang_edge, Color(0.9, 0.7, 0.4), 2.5)
		draw_line(top_right, _hang_edge, Color(0.9, 0.7, 0.4), 2.5)
		draw_circle(_hang_edge, 5.0, Color(1.0, 0.85, 0.4))

	# State label
	var state_text := "NORMAL" if _state == PState.NORMAL else "HANGING"
	var state_col := Color(0.5, 0.9, 0.5) if _state == PState.NORMAL else Color(1.0, 0.75, 0.2)
	draw_string(ThemeDB.fallback_font, Vector2(320, 50), state_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, state_col)

	# Title and hints
	draw_string(ThemeDB.fallback_font, Vector2(320, 28), "Ledge Hang", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(320, 468), "arrow keys: move/jump    up: pull-up    down: drop    (grab ledge automatically)", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.8, 0.8, 0.8))
