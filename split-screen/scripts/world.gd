extends Node2D

@onready var _cam: Camera2D         = $Camera2D
@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	# Ensure the camera starts on the player
	_cam.position = _player.position

func _process(_delta: float) -> void:
	# Smoothly follow player (instant snap — no built-in smoothing so motion is clear)
	_cam.global_position = _player.global_position

func _draw() -> void:
	# Floor — dark grey bar
	draw_rect(Rect2(0.0, 460.0, 320.0, 20.0), Color(0.28, 0.28, 0.32))
	# Platforms — brown bars
	draw_rect(Rect2(30.0,  380.0, 100.0, 12.0), Color(0.45, 0.30, 0.15))
	draw_rect(Rect2(190.0, 320.0, 100.0, 12.0), Color(0.45, 0.30, 0.15))
	# Background tint
	draw_rect(Rect2(0.0, 0.0, 320.0, 460.0), Color(0.15, 0.18, 0.22))
