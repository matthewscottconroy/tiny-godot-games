extends Area2D

signal collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12, Color.GOLD)
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, Color.DARK_GOLDENROD, 2.0)

func _on_body_entered(_body: Node2D) -> void:
	collected.emit()
	queue_free()
