extends Node2D

var _time: float = 0.0

func _process(delta: float) -> void:
	_time    += delta
	position  = Vector2(460.0 + cos(_time * 0.7) * 100.0, 240.0 + sin(_time * 1.1) * 140.0)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 18, Color(0.75, 0.15, 0.15))
	draw_circle(Vector2.ZERO, 10, Color(0.95, 0.35, 0.35))
	draw_circle(Vector2.ZERO, 4,  Color.WHITE)
