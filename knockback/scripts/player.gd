extends CharacterBody2D

const SPEED      := 200.0
const JUMP_VEL   := -400.0
const GRAVITY    := 900.0
const KB_IMPULSE := 480.0
const KB_UP      := -260.0
const KB_DECAY   := 7.0

var _knockback := Vector2.ZERO
var _iframes   := 0.0
var _hp        := 5

@onready var _label: Label = $InfoLabel

func take_hit(from: Vector2) -> void:
	if _iframes > 0.0:
		return
	var dir    := (global_position - from).normalized()
	_knockback  = Vector2(dir.x * KB_IMPULSE, KB_UP)
	_iframes    = 0.8
	_hp         = maxi(_hp - 1, 0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_iframes   = maxf(_iframes - delta, 0.0)
	_knockback = _knockback.lerp(Vector2.ZERO, KB_DECAY * delta)

	var ctrl_x := Input.get_axis("ui_left", "ui_right") * SPEED
	velocity.x  = ctrl_x + _knockback.x
	if _knockback.y != 0.0:
		velocity.y   = _knockback.y
		_knockback.y = 0.0

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()
	_label.text = "HP: %d%s" % [_hp, "  [IFRAMES]" if _iframes > 0.0 else ""]

func _draw() -> void:
	var col := Color(1.0, 0.3, 0.3, 0.5) if _iframes > 0.0 else Color.DODGER_BLUE
	draw_rect(Rect2(-12, -24, 24, 48), col)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
