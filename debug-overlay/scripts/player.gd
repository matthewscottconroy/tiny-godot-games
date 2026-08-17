extends CharacterBody2D

const SPEED   := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

var state: String = "idle"

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if can_jump(Input.is_action_just_pressed("ui_up"), is_on_floor()):
		velocity.y = JUMP_VEL
	move_and_slide()
	queue_redraw()
	state = state_for(is_on_floor(), velocity.x)

func can_jump(jump_pressed: bool, on_floor: bool) -> bool:
	return jump_pressed and on_floor

## The word the overlay prints for what the player is doing.
##
## The speed threshold is not zero: a body resting against a wall keeps a hair
## of velocity, and calling that "run" would leave the readout twitching.
func state_for(on_floor: bool, horizontal_speed: float) -> String:
	if not on_floor:
		return "air"
	if absf(horizontal_speed) > 1.0:
		return "run"
	return "idle"

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
