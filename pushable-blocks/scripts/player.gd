extends CharacterBody2D

const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0
const PUSH_STR := 240.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL
	move_and_slide()

	for i in get_slide_collision_count():
		var col  := get_slide_collision(i)
		var body := col.get_collider()
		if body is CharacterBody2D and body.is_in_group("pushable"):
			# normal points from block toward player; negate to get push direction
			body.push(-col.get_normal().x * PUSH_STR)

	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-12, -20, 24, 40), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -16, 5, 5), Color.WHITE)
