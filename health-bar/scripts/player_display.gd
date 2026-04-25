extends Node2D

var hp_ratio := 1.0 :
	set(v):
		hp_ratio = v
		queue_redraw()

func _draw() -> void:
	var color := Color.CORNFLOWER_BLUE.lerp(Color.TOMATO, 1.0 - hp_ratio)
	draw_rect(Rect2(-16, -22, 32, 44), color)
	draw_circle(Vector2(0, -34), 14, color)
	if hp_ratio > 0.0:
		draw_rect(Rect2(-8, -38, 5, 5), Color.WHITE)
		draw_rect(Rect2(3, -38, 5, 5), Color.WHITE)
	else:
		draw_line(Vector2(-9, -40), Vector2(-3, -34), Color.WHITE, 2)
		draw_line(Vector2(-3, -40), Vector2(-9, -34), Color.WHITE, 2)
		draw_line(Vector2(2, -40), Vector2(8, -34), Color.WHITE, 2)
		draw_line(Vector2(8, -40), Vector2(2, -34), Color.WHITE, 2)
