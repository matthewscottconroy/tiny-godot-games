class_name Checkpoint
extends Area2D

@export var checkpoint_id: int = 0

var _activated := false

signal activated(id: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if body.is_in_group("player"):
		_activated = true
		activated.emit(checkpoint_id)
		queue_redraw()

func _draw() -> void:
	var pole_col  := Color(0.6, 0.6, 0.7)
	var flag_col  := Color.GREEN if _activated else Color.RED
	# Pole
	draw_rect(Rect2(-2, -60, 4, 60), pole_col)
	# Flag
	draw_polygon([Vector2(2, -60), Vector2(2, -38), Vector2(30, -49)], [flag_col])
	# Base glow when active
	if _activated:
		draw_circle(Vector2.ZERO, 10, Color(0.3, 1.0, 0.3, 0.4))
