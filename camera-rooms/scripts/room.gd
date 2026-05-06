extends Area2D

@export var room_name: String = "Room"
@export var cam_target: Vector2 = Vector2.ZERO

signal player_entered(room_name: String, cam_pos: Vector2)

func _ready() -> void:
	body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(room_name, cam_target)
