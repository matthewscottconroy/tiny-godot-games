extends Node2D

func _draw() -> void:
	# Body
	draw_rect(Rect2(-14, -20, 28, 36), Color.MEDIUM_PURPLE)
	# Head
	draw_circle(Vector2(0, -28), 14, Color.MEDIUM_PURPLE)
	# Eyes
	draw_rect(Rect2(-8, -33, 5, 5), Color.WHITE)
	draw_rect(Rect2(3, -33, 5, 5), Color.WHITE)
