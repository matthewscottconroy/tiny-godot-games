extends CharacterBody2D

const SPEED        := 200.0
const SPRINT_SPEED := 360.0
const JUMP_VEL     := -400.0
const GRAVITY      := 900.0
const STAMINA_MAX  := 100.0
const DRAIN_RATE   := 38.0
const REGEN_RATE   := 18.0
const REGEN_DELAY  := 0.8

var _stamina:       float = STAMINA_MAX
var _sprinting:     bool  = false
var _regen_wait:    float = 0.0

@onready var _bar:   ProgressBar = $StaminaBar
@onready var _label: Label       = $InfoLabel

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var h   := Input.get_axis("ui_left", "ui_right")
	var want_sprint := Input.is_key_pressed(KEY_SHIFT) and h != 0.0

	_sprinting = want_sprint and _stamina > 0.0

	if _sprinting:
		_stamina    = maxf(_stamina - DRAIN_RATE * delta, 0.0)
		_regen_wait = REGEN_DELAY
	else:
		_regen_wait = maxf(_regen_wait - delta, 0.0)
		if _regen_wait <= 0.0:
			_stamina = minf(_stamina + REGEN_RATE * delta, STAMINA_MAX)

	velocity.x = h * (SPRINT_SPEED if _sprinting else SPEED)
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL
	move_and_slide()
	queue_redraw()

	_bar.value  = _stamina
	_bar.modulate = Color.GREEN if _stamina > 30.0 else Color.ORANGE_RED
	_label.text = "SPRINTING" if _sprinting else ("DEPLETED" if _stamina <= 0.0 else "READY")

func _draw() -> void:
	var col := Color.GOLD if _sprinting else Color.DODGER_BLUE
	draw_rect(Rect2(-12, -24, 24, 48), col)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
