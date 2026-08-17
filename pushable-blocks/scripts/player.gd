extends CharacterBody2D

const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0
const PUSH_STR := 240.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if can_jump(Input.is_action_just_pressed("ui_up"), is_on_floor()):
		velocity.y = JUMP_VEL
	move_and_slide()

	for i in get_slide_collision_count():
		var col  := get_slide_collision(i)
		var body := col.get_collider()
		if is_pushable(body):
			body.push(push_from_normal(col.get_normal().x))

	queue_redraw()

func can_jump(jump_pressed: bool, on_floor: bool) -> bool:
	return jump_pressed and on_floor

## Only moving bodies that opted in get shoved.
##
## The group is the opt-in; the type check keeps the walls and the floor out of
## it, since a StaticBody2D has no push() to call.
func is_pushable(body: Node) -> bool:
	return body is CharacterBody2D and body.is_in_group("pushable")

## Turn a collision normal into a shove.
##
## The normal points from the block back towards the player, so pushing along
## it would send the block through the player. Negating it is the whole trick.
func push_from_normal(normal_x: float) -> float:
	return -normal_x * PUSH_STR

func _draw() -> void:
	draw_rect(Rect2(-12, -20, 24, 40), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -16, 5, 5), Color.WHITE)
