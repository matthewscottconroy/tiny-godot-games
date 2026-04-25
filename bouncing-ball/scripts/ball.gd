extends RigidBody2D

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, Color.TOMATO)
	draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(0.8, 0.2, 0.1), 2.0)
