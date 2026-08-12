extends CharacterBody2D

const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

var _spawn_point: Vector2

@onready var _label: Label = $InfoLabel

func _ready() -> void:
	_spawn_point = global_position
	add_to_group("player")

func set_checkpoint(pos: Vector2) -> void:
	_spawn_point = pos

func respawn() -> void:
	global_position = _spawn_point
	velocity = Vector2.ZERO

# R is a one-shot action, so it is handled as an event rather than polled every
# physics frame — one `pressed and not echo` event per physical press.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_R:
		respawn()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL
	move_and_slide()
	queue_redraw()
	_label.text = "Spawn: (%.0f, %.0f)\nPress R to respawn" % [_spawn_point.x, _spawn_point.y]

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
