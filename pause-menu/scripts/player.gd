extends CharacterBody2D

const SPEED    := 180.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	move_and_slide()
	queue_redraw()
