extends Node2D

const DEAD_W       := 80.0
const DEAD_H       := 40.0
const FOLLOW_SPEED := 4.5

@onready var _player: CharacterBody2D = $Player
@onready var _cam:    Camera2D         = $Camera2D
@onready var _status: Label            = $CanvasLayer/StatusLabel

func _process(delta: float) -> void:
	var offset := _player.global_position - _cam.global_position
	var target := _cam.global_position

	if offset.x > DEAD_W:
		target.x = _player.global_position.x - DEAD_W
	elif offset.x < -DEAD_W:
		target.x = _player.global_position.x + DEAD_W

	if offset.y > DEAD_H:
		target.y = _player.global_position.y - DEAD_H
	elif offset.y < -DEAD_H:
		target.y = _player.global_position.y + DEAD_H

	_cam.global_position = _cam.global_position.lerp(target, FOLLOW_SPEED * delta)

	var moving := not target.is_equal_approx(_cam.global_position)
	_status.text = "Camera: FOLLOWING" if moving else "Camera: STATIC (player in dead zone)"
	queue_redraw()

func _draw() -> void:
	# Visualize dead zone in camera space
	var vp     := get_viewport_rect().size
	var center := vp * 0.5
	draw_rect(Rect2(center.x - DEAD_W, center.y - DEAD_H, DEAD_W * 2, DEAD_H * 2),
		Color(1.0, 1.0, 0.3, 0.15))
	draw_rect(Rect2(center.x - DEAD_W, center.y - DEAD_H, DEAD_W * 2, DEAD_H * 2),
		Color(1.0, 1.0, 0.3, 0.6), false, 1.5)

	# World landmarks
	for i in 6:
		var wx := 300.0 + i * 400.0
		var wy_screen := wx - _cam.global_position.x + center.x
		if wy_screen > 0 and wy_screen < vp.x:
			draw_line(Vector2(wy_screen, 350), Vector2(wy_screen, 460), Color(0.5, 0.5, 0.6, 0.4), 1)
			draw_string(ThemeDB.fallback_font, Vector2(wy_screen - 10, 370),
				"x=%d" % int(wx), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.7, 0.7))
