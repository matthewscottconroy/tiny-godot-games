extends CharacterBody2D

const SPEED   := 180.0
const GRAVITY := 900.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -380.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14, Color.DODGER_BLUE)
	draw_circle(Vector2.ZERO, 10, Color(0.5, 0.8, 1.0))
	draw_circle(Vector2.ZERO, 4, Color.WHITE)
