extends CharacterBody2D

const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if can_jump(Input.is_action_just_pressed("ui_up"), is_on_floor()):
		velocity.y = JUMP_VEL
	move_and_slide()
	queue_redraw()

func can_jump(jump_pressed: bool, on_floor: bool) -> bool:
	return jump_pressed and on_floor

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
