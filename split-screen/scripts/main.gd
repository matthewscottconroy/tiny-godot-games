extends Control

func _draw() -> void:
	# Vertical dividing line between the two viewports
	draw_rect(Rect2(319.0, 0.0, 2.0, 480.0), Color(0.9, 0.9, 0.9, 1.0))
