extends PathFollow2D

@export var speed: float = 120.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color.TOMATO)
	draw_arc(Vector2.ZERO, 16, 0, TAU, 32, Color(0.7, 0.1, 0.1), 2.0)
	# Draw a direction indicator
	draw_line(Vector2.ZERO, Vector2(16, 0), Color.WHITE, 2.0)

func _process(delta: float) -> void:
	progress += speed * delta
	queue_redraw()
