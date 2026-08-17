extends CharacterBody2D

const SPEED    := 180.0
const JUMP_VEL := -520.0
const GRAVITY  := 900.0
const JUMP_CUT := 0.4

var _jumping := false

@onready var _label: Label = $InfoLabel

## Apply gravity, the jump, and the release cut, returning the new vertical
## velocity.
##
## Taking its inputs as parameters rather than reading Input and is_on_floor()
## directly is what lets the rule the demo exists to teach be driven from a
## test — and it is the whole rule, in order.
func tick_vertical(vy: float, delta: float, on_floor: bool,
		jump_pressed: bool, jump_released: bool) -> float:
	# Landing clears the flag, so a release after touching down cuts nothing.
	if on_floor:
		_jumping = false

	vy += GRAVITY * delta

	if on_floor and jump_pressed:
		vy = JUMP_VEL
		_jumping = true

	# The cut only applies while still RISING. Without that check, releasing on
	# the way down would scale the fall and the player would float.
	if _jumping and jump_released and vy < 0.0:
		vy *= JUMP_CUT
		_jumping = false

	return vy

func is_jumping() -> bool:
	return _jumping

func _physics_process(delta: float) -> void:
	velocity.y = tick_vertical(
		velocity.y, delta, is_on_floor(),
		Input.is_action_just_pressed("ui_up"),
		Input.is_action_just_released("ui_up"))

	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED

	move_and_slide()
	queue_redraw()

	if _label:
		var state := "rising" if velocity.y < -10.0 else ("falling" if velocity.y > 10.0 else "floor")
		_label.text = "vy: %+.0f  [%s]" % [velocity.y, state]

func _draw() -> void:
	draw_rect(Rect2(-14, -24, 28, 48), Color.MEDIUM_SEA_GREEN)
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3, -18, 5, 5), Color.WHITE)
