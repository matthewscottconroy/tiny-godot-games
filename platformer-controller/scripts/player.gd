extends CharacterBody2D

const SPEED       := 200.0
const JUMP_VEL    := -420.0
const GRAVITY     := 900.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.10

var _coyote := 0.0
var _buffer := 0.0

@onready var _label: Label = $InfoLabel

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)

	if Input.is_action_just_pressed("ui_up"):
		_buffer = JUMP_BUFFER
	_buffer = maxf(_buffer - delta, 0.0)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VEL
		_coyote    = 0.0
		_buffer    = 0.0

	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	move_and_slide()
	queue_redraw()
	_update_label()

func _draw() -> void:
	var col := Color.DODGER_BLUE if is_on_floor() else Color.ORANGE
	draw_rect(Rect2(-16, -28, 32, 56), col)
	draw_rect(Rect2(-8, -24, 6, 6), Color.WHITE)
	draw_rect(Rect2( 2, -24, 6, 6), Color.WHITE)

func _update_label() -> void:
	var parts: Array[String] = []
	if is_on_floor():
		parts.append("GROUNDED")
	elif _coyote > 0.0:
		parts.append("COYOTE %.2fs" % _coyote)
	else:
		parts.append("AIR")
	if _buffer > 0.0:
		parts.append("BUFFERED %.2fs" % _buffer)
	_label.text = " | ".join(parts)
