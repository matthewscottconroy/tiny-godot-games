extends RigidBody2D

var is_circle := false
var body_color := Color.ORANGE

func _draw() -> void:
	if is_circle:
		draw_circle(Vector2.ZERO, 15.0, body_color)
	else:
		draw_rect(Rect2(-16, -16, 32, 32), body_color)

func _process(_delta: float) -> void:
	queue_redraw()
