extends Node2D

const SPEED := 200.0
const JUMP_VEL := -360.0
const GRAVITY := 700.0
const HOOK_SPEED := 550.0
const SWING_DAMP := 0.993
const PLAYER_R := 12.0

const LEVEL := [
	Rect2(0, 440, 640, 40),
	Rect2(100, 320, 160, 20),
	Rect2(370, 240, 150, 20),
	Rect2(50, 160, 130, 20),
	Rect2(470, 160, 120, 20),
	Rect2(0, 0, 20, 480),
	Rect2(620, 0, 20, 480),
]

enum GState { IDLE, FLYING, ATTACHED }

var _pos: Vector2 = Vector2(300.0, 400.0)
var _vel: Vector2 = Vector2.ZERO
var _on_floor: bool = false
var _gstate: GState = GState.IDLE
var _hook_pos: Vector2 = Vector2.ZERO
var _hook_vel: Vector2 = Vector2.ZERO
var _rope_len: float = 0.0

func _ready() -> void:
	_reset()

func _reset() -> void:
	_pos = Vector2(300.0, 400.0)
	_vel = Vector2.ZERO
	_on_floor = false
	_gstate = GState.IDLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _gstate == GState.IDLE or _gstate == GState.ATTACHED:
			var direction := _pos.direction_to(event.position)
			_hook_vel = direction * HOOK_SPEED
			_hook_pos = _pos
			_gstate = GState.FLYING
		elif _gstate == GState.FLYING:
			_gstate = GState.IDLE

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reset()

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")

	match _gstate:
		GState.IDLE, GState.FLYING:
			_vel.y += GRAVITY * delta
			_vel.x = dir * SPEED

		GState.ATTACHED:
			_vel += Vector2(0.0, GRAVITY) * delta
			_vel *= pow(SWING_DAMP, delta)

			# Rope length constraint (pendulum)
			var rope := _pos - _hook_pos
			if rope.length() > _rope_len:
				var rope_dir := rope.normalized()
				_pos = _hook_pos + rope_dir * _rope_len
				# Remove outward radial velocity
				var radial := rope_dir * _vel.dot(rope_dir)
				if _vel.dot(rope_dir) > 0.0:
					_vel -= radial

			# Slight horizontal air control while swinging
			_vel.x += dir * 60.0 * delta

	_pos += _vel * delta
	_resolve_collisions()

	# Advance flying hook
	if _gstate == GState.FLYING:
		_hook_pos += _hook_vel * delta

		# Check if hook hit a platform
		for rect in LEVEL:
			if rect.has_point(_hook_pos):
				# Clamp hook to platform surface (just keep the point inside)
				_hook_pos = _hook_pos.clamp(rect.position, rect.position + rect.size)
				_rope_len = _pos.distance_to(_hook_pos)
				_gstate = GState.ATTACHED
				break

		# Hook went off screen
		if _hook_pos.x < 0.0 or _hook_pos.x > 640.0 or _hook_pos.y < 0.0 or _hook_pos.y > 480.0:
			_gstate = GState.IDLE

	queue_redraw()

func _resolve_collisions() -> void:
	_on_floor = false
	for rect in LEVEL:
		# Expand rect by player radius for circle vs AABB
		var expanded := Rect2(rect.position - Vector2(PLAYER_R, PLAYER_R), rect.size + Vector2(PLAYER_R * 2.0, PLAYER_R * 2.0))
		if not expanded.has_point(_pos):
			continue

		# Find overlap and push out on the smallest axis
		var overlap_left   := (rect.position.x + rect.size.x + PLAYER_R) - _pos.x
		var overlap_right  := _pos.x - (rect.position.x - PLAYER_R)
		var overlap_top    := (rect.position.y + rect.size.y + PLAYER_R) - _pos.y
		var overlap_bottom := _pos.y - (rect.position.y - PLAYER_R)

		# Determine minimum penetration axis
		var min_x := minf(overlap_left, overlap_right)
		var min_y := minf(overlap_top, overlap_bottom)

		if min_x < min_y:
			if overlap_left < overlap_right:
				_pos.x = rect.position.x + rect.size.x + PLAYER_R
				if _vel.x < 0.0:
					_vel.x = 0.0
			else:
				_pos.x = rect.position.x - PLAYER_R
				if _vel.x > 0.0:
					_vel.x = 0.0
		else:
			if overlap_top < overlap_bottom:
				_pos.y = rect.position.y + rect.size.y + PLAYER_R
				if _vel.y < 0.0:
					_vel.y = 0.0
			else:
				_pos.y = rect.position.y - PLAYER_R
				if _vel.y > 0.0:
					_vel.y = 0.0
				_on_floor = true

	# Jump
	if _on_floor and Input.is_action_pressed("ui_up"):
		_vel.y = JUMP_VEL

func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.12, 0.12, 0.18))

	# Platforms
	for rect in LEVEL:
		draw_rect(rect, Color(0.55, 0.35, 0.15))
		draw_rect(rect, Color(0.3, 0.2, 0.05), false, 2.0)

	# Grapple rope and hook
	if _gstate == GState.FLYING:
		draw_line(_pos, _hook_pos, Color(0.8, 0.8, 0.2), 2.0)
		draw_circle(_hook_pos, 5.0, Color(1.0, 0.8, 0.0))
	elif _gstate == GState.ATTACHED:
		draw_line(_pos, _hook_pos, Color(0.8, 0.8, 0.2), 2.0)
		draw_circle(_hook_pos, 7.0, Color(1.0, 0.6, 0.0))
		draw_arc(_hook_pos, 7.0, 0.0, TAU, 24, Color.BLACK, 1.5)

	# Player
	draw_circle(_pos, PLAYER_R, Color(0.2, 0.6, 1.0))
	draw_arc(_pos, PLAYER_R, 0.0, TAU, 32, Color.WHITE, 2.0)

	# UI
	draw_string(font, Vector2(8, 20), "Grapple Hook", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(8, 38), "Left/Right: move   Up: jump   Click: shoot/cancel grapple   R: reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.75, 0.75))

	var state_name := ""
	match _gstate:
		GState.IDLE: state_name = "IDLE"
		GState.FLYING: state_name = "FLYING"
		GState.ATTACHED: state_name = "ATTACHED"
	draw_string(font, Vector2(8, 472), "State: " + state_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.9, 0.6))
