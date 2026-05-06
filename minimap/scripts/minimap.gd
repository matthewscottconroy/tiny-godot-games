extends Node2D

## Draws the minimap overlay.  This node is a child of a CanvasLayer so it
## renders in screen space, independent of the scrolling Camera2D.

const WORLD_W := 2000.0
const WORLD_H := 480.0
const MAP_RECT := Rect2(460, 10, 170, 100)

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

# Set by main.gd each frame
var player_world_pos: Vector2 = Vector2.ZERO
var cam_world_pos:    Vector2 = Vector2.ZERO

func _draw() -> void:
	# Background
	draw_rect(MAP_RECT, Color(0, 0, 0, 0.7))
	# Border
	draw_rect(MAP_RECT, Color.WHITE, false, 1.0)

	# Platforms
	for plat in PLATFORMS:
		var tl := _world_to_map(plat.position)
		var br := _world_to_map(plat.position + plat.size)
		draw_rect(Rect2(tl, br - tl), Color(0.55, 0.4, 0.25))

	# Camera viewport rect
	var cam_tl := _world_to_map(cam_world_pos - Vector2(320, 240))
	var cam_br := _world_to_map(cam_world_pos + Vector2(320, 240))
	draw_rect(Rect2(cam_tl, cam_br - cam_tl), Color(1, 1, 0, 0.22))
	draw_rect(Rect2(cam_tl, cam_br - cam_tl), Color(1, 1, 0, 0.7), false, 1.0)

	# Player dot
	draw_circle(_world_to_map(player_world_pos), 3.0, Color.LIME_GREEN)

func _world_to_map(world_pos: Vector2) -> Vector2:
	return MAP_RECT.position + world_pos / Vector2(WORLD_W, WORLD_H) * MAP_RECT.size
