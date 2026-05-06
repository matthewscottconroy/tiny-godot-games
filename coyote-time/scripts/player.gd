extends CharacterBody2D

const SPEED       := 200.0
const JUMP_VEL    := -420.0
const GRAVITY     := 900.0
const COYOTE_TIME := 0.12
const BUFFER_TIME := 0.15

var _coyote_timer  := 0.0
var _jump_buffer   := 0.0
var _was_on_floor  := false

@onready var _label: Label = $InfoLabel

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# 1. Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. Cache last frame's floor state before move_and_slide updates it
	var currently_on_floor := is_on_floor()

	# 3. If we just left the floor this frame, start coyote timer
	if _was_on_floor and not currently_on_floor:
		_coyote_timer = COYOTE_TIME

	# 4. While on the floor, keep coyote timer fresh (so it activates the moment we leave)
	if currently_on_floor:
		_coyote_timer = COYOTE_TIME

	# 5. Tick timers down (floor check happens before move_and_slide so values stay stable)
	_coyote_timer -= delta
	_jump_buffer  -= delta
	if _coyote_timer < 0.0:
		_coyote_timer = 0.0
	if _jump_buffer < 0.0:
		_jump_buffer = 0.0

	# 6. Record a jump-button press into the buffer
	if Input.is_action_just_pressed("ui_up"):
		_jump_buffer = BUFFER_TIME

	# 7. Execute a jump when both timers are live
	if _coyote_timer > 0.0 and _jump_buffer > 0.0:
		velocity.y    = JUMP_VEL
		_coyote_timer = 0.0
		_jump_buffer  = 0.0

	# 8. Horizontal movement
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED

	# 9. Resolve collisions
	move_and_slide()

	# 10. Update previous-frame floor state *after* move_and_slide
	_was_on_floor = is_on_floor()

	queue_redraw()
	if _label:
		_label.text = "Coyote: %.2f  Buffer: %.2f" % [_coyote_timer, _jump_buffer]

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3,  -18, 5, 5), Color.WHITE)
