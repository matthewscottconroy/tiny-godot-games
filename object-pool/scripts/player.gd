extends CharacterBody2D

const SPEED := 160.0

## How far in front of the player a shot is born. Far enough to clear the body,
## so a bullet is never drawn inside the thing that fired it.
const MUZZLE_OFFSET := 20.0

signal fired(from: Vector2, dir: Vector2)

var facing := Vector2.RIGHT

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)

## Where the next shot starts: in front of the player, along its facing.
func muzzle() -> Vector2:
	return global_position + facing * MUZZLE_OFFSET

## The way to face given this frame's input.
##
## Released keys read as a zero vector, and normalising that gives (0, 0) — so
## the aim has to be left alone rather than overwritten, or letting go would
## point the player at nothing.
func aim_for(dir: Vector2, current: Vector2) -> Vector2:
	return dir.normalized() if dir.length() > 0.0 else current

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	facing = aim_for(dir, facing)
	velocity = dir * SPEED
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		fired.emit(muzzle(), facing)
