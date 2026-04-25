extends CharacterBody2D

const SPEED := 200.0

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.STEEL_BLUE)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()
