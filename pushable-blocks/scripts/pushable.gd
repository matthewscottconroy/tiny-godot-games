extends CharacterBody2D

const GRAVITY  := 900.0
const FRICTION := 5.5

@export var block_color: Color = Color(0.80, 0.40, 0.10)

var _push_vel := 0.0

func _ready() -> void:
	add_to_group("pushable")

func push(horizontal_strength: float) -> void:
	_push_vel = horizontal_strength

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x    = _push_vel
	_push_vel      = lerpf(_push_vel, 0.0, FRICTION * delta)
	if absf(_push_vel) < 1.0:
		_push_vel = 0.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-18, -18, 36, 36), block_color)
	draw_rect(Rect2(-18, -18, 36, 36), block_color.lightened(0.35), false, 2.0)
