extends Node2D

func _draw() -> void:
	# Floor
	draw_rect(Rect2(0, 442, 640, 25), Color(0.25, 0.25, 0.25))
	# Outer walls
	draw_rect(Rect2(0, 80, 20, 362), Color(0.22, 0.22, 0.26))
	draw_rect(Rect2(620, 80, 20, 362), Color(0.22, 0.22, 0.26))
	# Inner walls (more practice surfaces)
	draw_rect(Rect2(200, 160, 16, 282), Color(0.22, 0.26, 0.22))
	draw_rect(Rect2(424, 160, 16, 282), Color(0.22, 0.26, 0.22))
