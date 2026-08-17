extends CharacterBody2D

const SPEED         := 200.0
const JUMP_VEL      := -420.0
const GRAVITY       := 900.0
const DASH_SPEED    := 650.0
const DASH_DURATION := 0.14
const DASH_COOLDOWN := 0.65
const IFRAME_TIME   := 0.20
const GHOST_MAX     := 8

var _dashing    := false
var _dash_timer := 0.0
var _cooldown   := 0.0
var _iframes    := 0.0
var _dash_dir   := 1.0
var _facing     := 1.0
var _ghosts:    Array[Vector2] = []

@onready var _label: Label = $InfoLabel

## Age the cooldown and the invincibility window, both clamped at zero.
func tick_timers(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_iframes  = maxf(_iframes  - delta, 0.0)

## Start a dash if one is allowed. Returns whether it began.
##
## The i-frames are shorter than the cooldown but longer than the dash itself,
## so the dash grants a little invulnerability on the way out — that overlap is
## what makes a dash feel like an escape rather than just fast movement.
func try_dash() -> bool:
	if _cooldown > 0.0 or _dashing:
		return false
	_dashing    = true
	_dash_timer = DASH_DURATION
	_dash_dir   = _facing
	_iframes    = IFRAME_TIME
	_cooldown   = DASH_COOLDOWN
	return true

## Age the active dash. Returns true while it is still running.
func advance_dash(delta: float) -> bool:
	if not _dashing:
		return false
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dashing = false
	return _dashing

func is_dashing() -> bool:
	return _dashing

func is_invincible() -> bool:
	return _iframes > 0.0

func cooldown_left() -> float:
	return _cooldown

func dash_direction() -> float:
	return _dash_dir

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var h := Input.get_axis("ui_left", "ui_right")
	if h != 0.0:
		_facing = sign(h)

	tick_timers(delta)

	if Input.is_action_just_pressed("ui_select") and try_dash():
		_ghosts.clear()

	if _dashing:
		_ghosts.append(global_position)
		if _ghosts.size() > GHOST_MAX:
			_ghosts.pop_front()
		velocity.x = _dash_dir * DASH_SPEED
		velocity.y = 0.0
		advance_dash(delta)
	else:
		velocity.x = h * SPEED
		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()
	_update_label()

func _draw() -> void:
	for i in _ghosts.size():
		var alpha := float(i) / GHOST_MAX * 0.4
		var gp    := to_local(_ghosts[i])
		draw_rect(Rect2(gp.x - 12, gp.y - 24, 24, 48), Color(0.4, 0.6, 1.0, alpha))
	var col := Color.YELLOW if _dashing else (Color(1.0, 0.5, 0.5) if _iframes > 0.0 else Color.DODGER_BLUE)
	draw_rect(Rect2(-12, -24, 24, 48), col)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2( 1, -20, 5, 5), Color.WHITE)

func _update_label() -> void:
	var parts: Array[String] = []
	if _dashing:
		parts.append("DASHING")
	elif _iframes > 0.0:
		parts.append("IFRAMES %.2fs" % _iframes)
	if _cooldown > 0.0:
		parts.append("CD %.2fs" % _cooldown)
	_label.text = " | ".join(parts) if parts.size() > 0 else "READY"
