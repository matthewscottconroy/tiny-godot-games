extends Sprite2D

@export var speed: float = 200.0

func _process(delta: float) -> void:
	move(delta, input_direction())

func input_direction() -> Vector2:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	return direction

## Move one frame's worth in the given direction.
##
## Normalised, so holding two arrows travels no faster than one — and guarded,
## because normalising a zero vector is a division by zero.
func move(delta: float, direction: Vector2) -> void:
	if direction.length_squared() > 0:
		position += direction.normalized() * speed * delta
