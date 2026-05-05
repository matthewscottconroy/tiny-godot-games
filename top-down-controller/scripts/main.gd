extends Node2D

func _draw() -> void:
	var wall_col := Color(0.35, 0.35, 0.4)
	var obs_col  := Color(0.45, 0.28, 0.15)
	# Walls
	draw_rect(Rect2(0,   0,   640,  20), wall_col)
	draw_rect(Rect2(0,   460, 640,  20), wall_col)
	draw_rect(Rect2(0,   20,  20,   440), wall_col)
	draw_rect(Rect2(620, 20,  20,   440), wall_col)
	# Obstacles
	draw_rect(Rect2(130, 170, 60, 60), obs_col)
	draw_rect(Rect2(420, 280, 80, 40), obs_col)
