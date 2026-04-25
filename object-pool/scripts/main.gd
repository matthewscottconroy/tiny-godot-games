extends Node2D

@onready var pool: Node2D = $BulletPool
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	player.fired.connect(_on_fired)

func _on_fired(from: Vector2, dir: Vector2) -> void:
	var bullet := pool.request_bullet()
	if bullet:
		bullet.fire(from, dir)
