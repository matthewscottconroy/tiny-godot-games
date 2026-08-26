extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const GRAVITY := 900.0

# Set by _unhandled_key_input on the frame a jump key goes down, consumed (and
# cleared) by the next _physics_process. Holding the key does not re-trigger,
# because only the initial press produces a non-echo event.
var _jump_requested := false

func _ready() -> void:
	add_to_group("player")

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_SPACE or key.keycode == KEY_UP or key.keycode == KEY_W:
		_jump_requested = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if _jump_requested:
		_jump_requested = false
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

	velocity.x = axis_from(
		Input.is_key_pressed(KEY_LEFT), Input.is_key_pressed(KEY_A),
		Input.is_key_pressed(KEY_RIGHT), Input.is_key_pressed(KEY_D)) * SPEED
	move_and_slide()
	queue_redraw()

## The movement axis, from either set of keys. Arrows and WASD are alternatives,
## so pressing one of a pair is enough — requiring both would mean holding two
## keys to walk in one direction.
##
## Extracted from _physics_process because the four flags come from Input, which
## a headless test cannot press.
static func axis_from(left: bool, alt_left: bool, right: bool, alt_right: bool) -> float:
	var dir := 0.0
	if left or alt_left:
		dir -= 1.0
	if right or alt_right:
		dir += 1.0
	return dir

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-6, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(1, -18, 5, 5), Color.WHITE)
