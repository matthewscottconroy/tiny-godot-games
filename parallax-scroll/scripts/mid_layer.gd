extends Node2D

# Rolling hills. Scrolls at 0.4x camera speed.
func _draw() -> void:
	for i in range(-1, 14):
		var x := i * 180
		draw_circle(Vector2(x, 430), 110, Color(0.18, 0.50, 0.22))
