extends Node2D

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	for cp in get_tree().get_nodes_in_group("checkpoint"):
		cp.activated.connect(_on_checkpoint.bind(cp))

func _on_checkpoint(cp: Area2D) -> void:
	_player.set_checkpoint(cp.global_position + Vector2(0, -30))

func _draw() -> void:
	draw_rect(Rect2(0, 455, 640, 25), Color(0.30, 0.30, 0.35))
	draw_rect(Rect2(0, 280, 160, 14), Color(0.40, 0.28, 0.16))
	draw_rect(Rect2(280, 200, 160, 14), Color(0.40, 0.28, 0.16))
	draw_rect(Rect2(480, 120, 160, 14), Color(0.40, 0.28, 0.16))
