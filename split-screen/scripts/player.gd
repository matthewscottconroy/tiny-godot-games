extends CharacterBody2D

@export var use_wasd: bool = true
@export var body_color: Color = Color.DODGER_BLUE

const SPEED    := 160.0
const JUMP_VEL := -360.0
const GRAVITY  := 800.0

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
	var jump_key := KEY_W if use_wasd else KEY_UP
	if Input.is_key_just_pressed(jump_key) and is_on_floor():
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Body
	draw_rect(Rect2(-10.0, -20.0, 20.0, 40.0), body_color)
	# Eyes
	draw_rect(Rect2(-8.0, -16.0, 4.0, 4.0), Color.WHITE)
	draw_rect(Rect2(4.0, -16.0, 4.0, 4.0), Color.WHITE)
