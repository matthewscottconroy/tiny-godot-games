extends CharacterBody2D

const SPEED := 160.0

signal fired(from: Vector2, dir: Vector2)

var facing := Vector2.RIGHT

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() > 0:
		facing = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		fired.emit(global_position + facing * 20, facing)
