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

## Age both forgiveness windows and decide whether a jump fires this frame.
##
## Kept as a method taking its inputs rather than reading Input and is_on_floor()
## directly, so the rule the demo exists to teach can be driven from a test. The
## body below is the whole mechanism; _physics_process only supplies the inputs.
func tick_jump(delta: float, on_floor: bool, jump_pressed: bool) -> bool:
	# Starting the coyote window on the frame we LEAVE the floor is the point —
	# doing it on the frame we land would be too late to help.
	if _was_on_floor and not on_floor:
		_coyote_timer = COYOTE_TIME

	# While grounded, keep it fresh so it is already full the moment we step off.
	if on_floor:
		_coyote_timer = COYOTE_TIME

	_coyote_timer -= delta
	_jump_buffer  -= delta
	if _coyote_timer < 0.0:
		_coyote_timer = 0.0
	if _jump_buffer < 0.0:
		_jump_buffer = 0.0

	# A press is remembered rather than consumed immediately, so pressing
	# slightly before landing still produces a jump.
	if jump_pressed:
		_jump_buffer = BUFFER_TIME

	# BOTH windows must be live. Either one alone is not a jump.
	var fires := _coyote_timer > 0.0 and _jump_buffer > 0.0
	if fires:
		_coyote_timer = 0.0
		_jump_buffer  = 0.0

	_was_on_floor = on_floor
	return fires

func coyote_left() -> float:
	return _coyote_timer

func buffer_left() -> float:
	return _jump_buffer

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Cache the floor state before move_and_slide() changes it.
	var currently_on_floor := is_on_floor()

	if tick_jump(delta, currently_on_floor, Input.is_action_just_pressed("ui_up")):
		velocity.y = JUMP_VEL

	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	move_and_slide()

	queue_redraw()
	if _label:
		_label.text = "Coyote: %.2f  Buffer: %.2f" % [_coyote_timer, _jump_buffer]

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	# Eyes
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3,  -18, 5, 5), Color.WHITE)
