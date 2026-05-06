extends Node2D

const WORLD_W := 2000.0
const WORLD_H := 480.0

# Platform rects in world space — used for drawing terrain and collision floor
const PLATFORMS: Array = [
	Rect2(0,    455, 2000, 25),
	Rect2(200,  360,  160, 14),
	Rect2(480,  290,  160, 14),
	Rect2(760,  340,  120, 14),
	Rect2(1000, 260,  180, 14),
	Rect2(1280, 310,  140, 14),
	Rect2(1500, 230,  160, 14),
	Rect2(1750, 360,  180, 14),
]

@onready var _player:  CharacterBody2D = $Player
@onready var _cam:     Camera2D        = $Camera2D
@onready var _minimap: Node2D          = $CanvasLayer/Minimap

func _process(_delta: float) -> void:
	# Camera follows player x, clamped so it never shows outside the world
	_cam.position = Vector2(
		clampf(_player.global_position.x, 320.0, WORLD_W - 320.0),
		240.0
	)
	# Feed current world positions to the screen-space minimap
	_minimap.player_world_pos = _player.global_position
	_minimap.cam_world_pos    = _cam.position
	_minimap.queue_redraw()
	queue_redraw()

func _draw() -> void:
	# World background
	draw_rect(Rect2(0, 0, WORLD_W, WORLD_H), Color(0.12, 0.12, 0.18))

	# Draw terrain (world space)
	for plat in PLATFORMS:
		var col := Color(0.35, 0.25, 0.15) if plat.size.y <= 20.0 else Color(0.28, 0.28, 0.33)
		draw_rect(plat, col)
