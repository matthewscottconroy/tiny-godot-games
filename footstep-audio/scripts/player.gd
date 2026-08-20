extends CharacterBody2D

signal stepped(surface: String)

const SPEED          := 180.0
const GRAVITY        := 900.0
const STEP_INTERVAL  := 0.34

## Below this horizontal speed the player is shuffling, not walking. Without it
## a body settling against a wall would tap out footsteps on the spot.
const WALK_THRESHOLD := 20.0

var _step_timer      := 0.0
var _current_surface := "stone"

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -380.0
	move_and_slide()

	if tick_steps(delta, is_on_floor(), velocity.x):
		stepped.emit(_current_surface)

	queue_redraw()

## Advance the footstep timer. Returns true on the frame a step lands.
##
## Separated from _physics_process because the speed it reads is recomputed from
## Input every frame — headless, the player never walks, so the pacing could not
## be driven from outside. The timer resets to zero rather than pausing when the
## player stops, so the next stride starts with a step rather than partway
## through the gap.
func tick_steps(delta: float, on_floor: bool, speed: float) -> bool:
	if not on_floor or absf(speed) <= WALK_THRESHOLD:
		_step_timer = 0.0
		return false
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = STEP_INTERVAL
		return true
	return false

func _draw() -> void:
	draw_rect(Rect2(-14, -28, 28, 52), Color.STEEL_BLUE)
	draw_rect(Rect2(-7, -23, 5, 5), Color.WHITE)
	draw_rect(Rect2( 2, -23, 5, 5), Color.WHITE)

func set_surface(name: String) -> void:
	_current_surface = name
