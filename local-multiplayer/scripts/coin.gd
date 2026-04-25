extends Area2D

signal collected(player_id: int)

func _ready() -> void:
	body_entered.connect(func(body: Node2D):
		if "player_id" in body:
			collected.emit(body.player_id)
			queue_free())

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10, Color.GOLD)
	draw_circle(Vector2.ZERO, 10, Color.YELLOW, false, 2)
