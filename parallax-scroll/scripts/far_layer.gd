extends Node2D

# Sky background + distant mountains. Scrolls at 0.1x camera speed.
func _draw() -> void:
	draw_rect(Rect2(-800, -300, 3200, 800), Color(0.42, 0.62, 0.85))
	for i in range(-1, 12):
		var x := i * 280
		draw_polygon(
			[Vector2(x, 420), Vector2(x + 140, 180), Vector2(x + 280, 420)],
			[Color(0.48, 0.52, 0.64)]
		)
