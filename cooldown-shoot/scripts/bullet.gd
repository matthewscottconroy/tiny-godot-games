extends Area2D

var direction := Vector2.RIGHT
const SPEED := 500.0
var _lifetime := 1.6

func _process(delta: float) -> void:
	position += direction * SPEED * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-8, -3, 16, 6), Color.YELLOW)
