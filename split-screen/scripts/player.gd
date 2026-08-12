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
	if key.keycode == (KEY_W if use_wasd else KEY_UP):
		_jump_requested = true

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Horizontal input — split by player type to avoid sharing ui_left/ui_right
	var h := 0.0
	if use_wasd:
		h = (1.0 if Input.is_key_pressed(KEY_D) else 0.0) \
		  - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
	else:
		h = (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0) \
		  - (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0)

	velocity.x = h * SPEED

	# Jump
	if _jump_requested:
		_jump_requested = false
		if is_on_floor():
			velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Body
	draw_rect(Rect2(-10.0, -20.0, 20.0, 40.0), body_color)
	# Eyes
	draw_rect(Rect2(-8.0, -16.0, 4.0, 4.0), Color.WHITE)
	draw_rect(Rect2(4.0, -16.0, 4.0, 4.0), Color.WHITE)
