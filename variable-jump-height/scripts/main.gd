extends Node2D

func _draw() -> void:
	# Floor
	draw_rect(Rect2(0, 442, 640, 25), Color(0.25, 0.25, 0.25))
	# Low platforms (reachable with short tap)
	draw_rect(Rect2(80, 370, 130, 16), Color(0.3, 0.5, 0.3))
	draw_rect(Rect2(430, 370, 130, 16), Color(0.3, 0.5, 0.3))
	# Mid platforms (need partial hold)
	draw_rect(Rect2(200, 300, 120, 16), Color(0.5, 0.5, 0.2))
	draw_rect(Rect2(320, 300, 120, 16), Color(0.5, 0.5, 0.2))
	# High platform (full hold required)
	draw_rect(Rect2(240, 210, 160, 16), Color(0.5, 0.3, 0.3))
