extends CharacterBody2D

const SPEED := 160.0

func _draw() -> void:
	draw_rect(Rect2(-12, -18, 24, 36), Color.CORNFLOWER_BLUE)
	draw_circle(Vector2(0, -26), 12, Color(0.8, 0.65, 0.5))

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()
