extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const GRAVITY := 900.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_key_just_pressed(KEY_SPACE) or Input.is_key_just_pressed(KEY_UP) or Input.is_key_just_pressed(KEY_W):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0

	velocity.x = dir * SPEED
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-6, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(1, -18, 5, 5), Color.WHITE)
