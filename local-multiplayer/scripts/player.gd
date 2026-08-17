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
	if uses_wasd():
		return axis_from(
			Input.is_key_pressed(KEY_D), Input.is_key_pressed(KEY_A),
			Input.is_key_pressed(KEY_S), Input.is_key_pressed(KEY_W))
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

## Player one is on WASD; everyone else uses the ui_* actions.
##
## Two players on one keyboard cannot share a set of keys, and the ui_* actions
## are already bound to the arrows — so only one player can use them.
func uses_wasd() -> bool:
	return player_id == 1

## Turn four held keys into a direction, with opposite keys cancelling out.
func axis_from(right: bool, left: bool, down: bool, up: bool) -> Vector2:
	return Vector2(float(right) - float(left), float(down) - float(up))
