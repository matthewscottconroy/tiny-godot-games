extends CharacterBody2D

const SPEED := 200.0

func _draw() -> void:
	draw_rect(Rect2(-12, -18, 24, 36), Color.CORNFLOWER_BLUE)

func _physics_process(_delta: float) -> void:
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	move_and_slide()
