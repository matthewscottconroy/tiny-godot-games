extends Node2D

@onready var camera: Camera2D = $Camera2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space / Enter
		shake()

func shake(duration: float = 0.4, strength: float = 12.0) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.04)
	for i in steps:
		var offset := Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "offset", offset, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.06)

func _draw() -> void:
	# Draw some static geometry so the shake is visible
	draw_rect(Rect2(60, 180, 80, 100), Color.SLATE_GRAY)
	draw_rect(Rect2(260, 200, 120, 80), Color.SLATE_GRAY)
	draw_rect(Rect2(460, 160, 90, 120), Color.SLATE_GRAY)
	draw_rect(Rect2(0, 440, 640, 20), Color.DIM_GRAY)
