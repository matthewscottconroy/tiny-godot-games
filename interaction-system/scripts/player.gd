extends CharacterBody2D

const SPEED   := 180.0
const GRAVITY := 900.0

var _nearby: Interactable = null

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -380.0
	if Input.is_action_just_pressed("ui_accept"):
		if _nearby:
			_nearby.interact()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-14, -26, 28, 52), Color.STEEL_BLUE)
	draw_rect(Rect2(-7, -22, 5, 5), Color.WHITE)
	draw_rect(Rect2( 2, -22, 5, 5), Color.WHITE)

func set_nearby(i: Interactable) -> void:
	_nearby = i
