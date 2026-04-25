extends Area2D

func _ready() -> void:
	queue_redraw()
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14, Color.GOLD)
	draw_arc(Vector2.ZERO, 14, 0, TAU, 32, Color.DARK_GOLDENROD, 2.0)
