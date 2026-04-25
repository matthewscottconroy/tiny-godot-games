extends Node2D

const ROOM_W := 1280
const ROOM_H := 960

func _ready() -> void:
	var cam: Camera2D = $Player/Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = ROOM_W
	cam.limit_bottom = ROOM_H

func _draw() -> void:
	# Room floor pattern (decorative grid to show scrolling)
	for row in range(0, ROOM_H, 80):
		for col in range(0, ROOM_W, 80):
			var shade := 0.18 if ((row + col) / 80) % 2 == 0 else 0.22
			draw_rect(Rect2(col, row, 80, 80), Color(shade, shade, shade))
	# Interior obstacle boxes
	draw_rect(Rect2(200, 200, 120, 120), Color.DIM_GRAY)
	draw_rect(Rect2(700, 300, 80, 200), Color.DIM_GRAY)
	draw_rect(Rect2(400, 600, 200, 80), Color.DIM_GRAY)
	draw_rect(Rect2(900, 700, 150, 100), Color.DIM_GRAY)
