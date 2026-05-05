extends CharacterBody2D

signal stepped(surface: String)

const SPEED          := 180.0
const GRAVITY        := 900.0
const STEP_INTERVAL  := 0.34

var _step_timer      := 0.0
var _current_surface := "stone"

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -380.0
	move_and_slide()

	if is_on_floor() and absf(velocity.x) > 20.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = STEP_INTERVAL
			stepped.emit(_current_surface)
	else:
		_step_timer = 0.0

	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-14, -28, 28, 52), Color.STEEL_BLUE)
	draw_rect(Rect2(-7, -23, 5, 5), Color.WHITE)
	draw_rect(Rect2( 2, -23, 5, 5), Color.WHITE)

func set_surface(name: String) -> void:
	_current_surface = name
