extends CharacterBody2D

@export var use_wasd: bool = true
@export var body_color: Color = Color.DODGER_BLUE

const SPEED    := 160.0
const JUMP_VEL := -360.0
const GRAVITY  := 800.0

# Latched by _unhandled_key_input on the press edge, consumed by _physics_process.
var _jump_requested := false

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == jump_key():
		request_jump()

# Each player owns its own keys rather than sharing ui_left/ui_right — two
# players on one keyboard cannot both use the same action.
func jump_key() -> Key:
	return KEY_W if use_wasd else KEY_UP

func left_key() -> Key:
	return KEY_A if use_wasd else KEY_LEFT

func right_key() -> Key:
	return KEY_D if use_wasd else KEY_RIGHT

func request_jump() -> void:
	_jump_requested = true

func input_axis() -> float:
	return (1.0 if Input.is_key_pressed(right_key()) else 0.0) \
		- (1.0 if Input.is_key_pressed(left_key()) else 0.0)

## One step of movement, given this frame's input and floor contact.
##
## A jump request is consumed whether or not it lands: pressing jump in mid-air
## must not queue a jump that fires the moment the player touches down.
func tick_velocity(delta: float, h: float, on_floor: bool) -> void:
	if not on_floor:
		velocity.y += GRAVITY * delta

	velocity.x = h * SPEED

	if _jump_requested:
		_jump_requested = false
		if on_floor:
			velocity.y = JUMP_VEL

func jump_requested() -> bool:
	return _jump_requested

func _physics_process(delta: float) -> void:
	tick_velocity(delta, input_axis(), is_on_floor())
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Body
	draw_rect(Rect2(-10.0, -20.0, 20.0, 40.0), body_color)
	# Eyes
	draw_rect(Rect2(-8.0, -16.0, 4.0, 4.0), Color.WHITE)
	draw_rect(Rect2(4.0, -16.0, 4.0, 4.0), Color.WHITE)
