extends CharacterBody2D

const SPEED    := 180.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED

	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3,  -18, 5, 5), Color.WHITE)
