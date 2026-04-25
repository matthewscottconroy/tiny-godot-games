extends Node2D

# Trees + ground strip. Scrolls at 0.75x camera speed.
func _draw() -> void:
	draw_rect(Rect2(-800, 380, 4000, 200), Color(0.12, 0.36, 0.12))
	for i in range(-1, 20):
		var x := i * 96
		draw_rect(Rect2(x + 38, 290, 10, 100), Color(0.35, 0.22, 0.10))
		draw_circle(Vector2(x + 43, 275), 26, Color(0.08, 0.32, 0.10))
