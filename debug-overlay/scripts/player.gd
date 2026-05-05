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
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL
	move_and_slide()
	queue_redraw()

	if not is_on_floor():
		state = "air"
	elif absf(velocity.x) > 1.0:
		state = "run"
	else:
		state = "idle"

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
