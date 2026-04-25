extends CharacterBody2D

@export var player_id    := 1
@export var player_color := Color.CORNFLOWER_BLUE

const SPEED := 180.0

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), player_color)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)
	# Hat to distinguish players
	draw_rect(Rect2(-16, -26, 32, 8), player_color.darkened(0.3))

func _physics_process(_delta: float) -> void:
	velocity = _get_dir() * SPEED
	move_and_slide()
	queue_redraw()

func _get_dir() -> Vector2:
	if player_id == 1:
		return Vector2(
			float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		)
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
