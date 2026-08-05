extends CharacterBody2D

const SPEED    := 180.0
const JUMP_VEL := -520.0
const GRAVITY  := 900.0
const JUMP_CUT := 0.4

var _jumping := false

@onready var _label: Label = $InfoLabel

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_jumping = false

	velocity.y += GRAVITY * delta

	var h := Input.get_axis("ui_left", "ui_right")
	velocity.x = h * SPEED

	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL
		_jumping = true

	if _jumping and Input.is_action_just_released("ui_up") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
		_jumping = false

	move_and_slide()
	queue_redraw()

	if _label:
		var state := "rising" if velocity.y < -10.0 else ("falling" if velocity.y > 10.0 else "floor")
		_label.text = "vy: %+.0f  [%s]" % [velocity.y, state]

func _draw() -> void:
	draw_rect(Rect2(-14, -24, 28, 48), Color.MEDIUM_SEA_GREEN)
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3, -18, 5, 5), Color.WHITE)
