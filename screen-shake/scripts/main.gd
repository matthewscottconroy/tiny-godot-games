extends Node2D

const STEP_TIME   := 0.04   # how long the camera rests on each random offset
const SETTLE_TIME := 0.06   # slightly slower return, so the shake ends softly

@onready var camera: Camera2D = $Camera2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space / Enter
		shake()

func shake(duration: float = 0.4, strength: float = 12.0) -> void:
	var offsets := shake_offsets(duration, strength)
	var tween := create_tween()
	for i in offsets.size():
		tween.tween_property(camera, "offset", offsets[i], step_duration(i, offsets.size()))

## How long the camera rests on offset `index` of `count`.
##
## The last entry is the return to centre and gets its own, slower timing —
## snapping back at shake speed reads as one more jolt rather than a settle.
func step_duration(index: int, count: int) -> float:
	return SETTLE_TIME if index == count - 1 else STEP_TIME

func shake_steps(duration: float) -> int:
	return maxi(int(duration / STEP_TIME), 0)

## The offsets one shake tweens through, ending centred.
##
## Kept separate from the tween so the shake is a plain list of positions:
## easy to test, and easy to swap for a noise curve or a decaying envelope.
func shake_offsets(duration: float, strength: float) -> PackedVector2Array:
	var offsets := PackedVector2Array()
	for i in shake_steps(duration):
		offsets.append(Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		))
	# Always finish at zero — otherwise the camera keeps whatever offset the
	# last random step happened to land on.
	offsets.append(Vector2.ZERO)
	return offsets

func _draw() -> void:
	# Draw some static geometry so the shake is visible
	draw_rect(Rect2(60, 180, 80, 100), Color.SLATE_GRAY)
	draw_rect(Rect2(260, 200, 120, 80), Color.SLATE_GRAY)
	draw_rect(Rect2(460, 160, 90, 120), Color.SLATE_GRAY)
	draw_rect(Rect2(0, 440, 640, 20), Color.DIM_GRAY)
