extends CharacterBody2D

const SPEED := 200.0

var joystick: Control = null

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	if joystick:
		velocity = joystick.direction * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color.DODGER_BLUE)
	draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 32, Color(0.4, 0.6, 1.0), 2.0)
	# Direction dot
	if joystick and joystick.direction.length() > 0.05:
		var dot_pos := joystick.direction * 7.0
		draw_circle(dot_pos, 3.0, Color.WHITE)
