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

func _physics_process(delta: float) -> void:
	# Gravity — reduced when sliding down a wall
	var on_wall := is_on_wall()
	var on_floor := is_on_floor()
	var h_input := Input.get_axis("ui_left", "ui_right")

	var pressing_toward_wall := false
	if on_wall and not on_floor:
		var wn := get_wall_normal()
		# Pressing toward the wall means the sign of h_input is opposite to wall normal
		pressing_toward_wall = (h_input * wn.x) < 0.0

	var grav_scale := WALL_SLIDE_GRAV if (on_wall and pressing_toward_wall and not on_floor) else 1.0
	velocity.y += GRAVITY * grav_scale * delta

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
		var wn := get_wall_normal()
		velocity = Vector2(-wn.x * WALL_JUMP_VX, JUMP_VEL)

	move_and_slide()
	queue_redraw()

	if _label:
		_label.text = "Floor:%s Wall:%s" % [is_on_floor(), is_on_wall()]

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3,  -18, 5, 5), Color.WHITE)
