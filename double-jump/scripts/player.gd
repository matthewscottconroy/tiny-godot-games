extends CharacterBody2D

const SPEED     := 180.0
const JUMP_VEL  := -420.0
const GRAVITY   := 900.0
const MAX_JUMPS := 2

var _jumps_left := 0

@onready var _label: Label = $InfoLabel

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_jumps_left = MAX_JUMPS

	velocity.y += GRAVITY * delta

	var h := Input.get_axis("ui_left", "ui_right")
	velocity.x = h * SPEED

	if Input.is_action_just_pressed("ui_up") and _jumps_left > 0:
		velocity.y = JUMP_VEL
		_jumps_left -= 1

	move_and_slide()
	queue_redraw()

	if _label:
		_label.text = "Jumps left: %d / %d" % [_jumps_left, MAX_JUMPS]

func _draw() -> void:
	draw_rect(Rect2(-14, -24, 28, 48), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3, -18, 5, 5), Color.WHITE)
