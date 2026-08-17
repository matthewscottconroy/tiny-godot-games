extends CharacterBody2D

const SPEED           := 180.0
const JUMP_VEL        := -420.0
const GRAVITY         := 900.0
const WALL_SLIDE_GRAV := 0.2
const WALL_JUMP_VX    := 300.0

var _facing := 1.0

@onready var _label: Label = $InfoLabel

func _ready() -> void:
	add_to_group("player")

## Pressing INTO the wall while airborne. `wall_normal_x` points away from the
## wall, so pressing into it means the input has the opposite sign.
func is_wall_sliding(h_input: float, on_wall: bool, on_floor: bool, wall_normal_x: float) -> bool:
	if not on_wall or on_floor:
		return false
	return (h_input * wall_normal_x) < 0.0

func gravity_scale(sliding: bool) -> float:
	return WALL_SLIDE_GRAV if sliding else 1.0

## The launch velocity for a wall jump.
##
## The horizontal component follows the wall normal, which points AWAY from the
## wall. Negating it — as this demo did until a test was written for it — throws
## the player back into the wall they are trying to leave.
func wall_jump_velocity(wall_normal_x: float) -> Vector2:
	return Vector2(wall_normal_x * WALL_JUMP_VX, JUMP_VEL)

func _physics_process(delta: float) -> void:
	# Gravity — reduced when sliding down a wall
	var on_wall := is_on_wall()
	var on_floor := is_on_floor()
	var h_input := Input.get_axis("ui_left", "ui_right")

	var wall_normal_x := get_wall_normal().x if on_wall else 0.0
	var sliding := is_wall_sliding(h_input, on_wall, on_floor, wall_normal_x)
	velocity.y += GRAVITY * gravity_scale(sliding) * delta

	# Horizontal movement
	if h_input != 0.0:
		_facing = h_input
		velocity.x = h_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Jump from floor
	if on_floor and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL

	# Wall jump
	if on_wall and not on_floor and Input.is_action_just_pressed("ui_up"):
		velocity = wall_jump_velocity(wall_normal_x)

	move_and_slide()
	queue_redraw()

	if _label:
		_label.text = "Floor:%s Wall:%s" % [is_on_floor(), is_on_wall()]

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3,  -18, 5, 5), Color.WHITE)
