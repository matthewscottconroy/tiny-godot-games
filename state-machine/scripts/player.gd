extends CharacterBody2D

enum State { IDLE, WALK, JUMP, FALL }

const SPEED    := 200.0
const JUMP_VEL := -420.0
const GRAVITY  := 900.0

var state := State.IDLE

@onready var state_label: Label = $StateLabel

func _draw() -> void:
	var color := {
		State.IDLE: Color.SEA_GREEN,
		State.WALK: Color.LIME_GREEN,
		State.JUMP: Color.SKY_BLUE,
		State.FALL: Color.ORANGE,
	}[state]
	draw_rect(Rect2(-16, -28, 32, 56), color)
	draw_rect(Rect2(-8, -24, 6, 6), Color.WHITE)
	draw_rect(Rect2(2, -24, 6, 6), Color.WHITE)

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * SPEED
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL
	move_and_slide()
	_transition()
	queue_redraw()

func _transition() -> void:
	var prev := state
	if is_on_floor():
		state = State.WALK if abs(velocity.x) > 10 else State.IDLE
	else:
		state = State.JUMP if velocity.y < 0 else State.FALL
	if state != prev:
		state_label.text = State.keys()[state]

func _ready() -> void:
	state_label.text = State.keys()[state]
