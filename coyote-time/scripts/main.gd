extends Node2D

func _draw() -> void:
	# Floor
	draw_rect(Rect2(0, 442, 640, 25), Color(0.25, 0.25, 0.25))

	# Narrow platform (great for testing coyote time — easy to run off the edge)
	draw_rect(Rect2(160, 313, 80, 14), Color(0.35, 0.35, 0.38))

	# Wider platform
	draw_rect(Rect2(380, 253, 140, 14), Color(0.35, 0.35, 0.38))
