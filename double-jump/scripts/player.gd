extends CharacterBody2D

const SPEED     := 180.0
const JUMP_VEL  := -420.0
const GRAVITY   := 900.0
const MAX_JUMPS := 2

var _jumps_left := 0

@onready var _label: Label = $InfoLabel

## Refill on landing, spend on jumping. Kept as a method taking its inputs so
## the counter rule — the whole lesson — can be driven from a test.
##
## A counter rather than a `has_double_jumped` boolean is what makes this scale:
## triple jumps and air-charges need no other change.
func tick_jump(on_floor: bool, jump_pressed: bool) -> bool:
	if on_floor:
		_jumps_left = MAX_JUMPS
	if jump_pressed and _jumps_left > 0:
		_jumps_left -= 1
		return true
	return false

func jumps_left() -> int:
	return _jumps_left

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED

	if tick_jump(is_on_floor(), Input.is_action_just_pressed("ui_up")):
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()

	if _label:
		_label.text = "Jumps left: %d / %d" % [_jumps_left, MAX_JUMPS]

func _draw() -> void:
	draw_rect(Rect2(-14, -24, 28, 48), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3, -18, 5, 5), Color.WHITE)
