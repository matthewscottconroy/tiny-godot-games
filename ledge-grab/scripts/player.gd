extends CharacterBody2D

const SPEED        := 180.0
const JUMP_VEL     := -400.0
const GRAVITY      := 900.0
const WALL_SLIDE   := 60.0   # max fall speed while sliding a wall
const WALL_JUMP_X  := 260.0  # horizontal push away from wall
const WALL_JUMP_Y  := -380.0

enum State { IDLE, RUN, JUMP, FALL, WALL_SLIDE }
var state := State.IDLE

@onready var _label: Label = $StateLabel

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")

	if is_on_floor():
		velocity.y = 0.0
		velocity.x = dir * SPEED
		if Input.is_action_just_pressed("ui_up"):
			velocity.y = JUMP_VEL
	elif is_on_wall_only():
		# Slide down slowly
		velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE)
		velocity.x = 0.0
		if Input.is_action_just_pressed("ui_up"):
			var normal := get_wall_normal()
			velocity.x = normal.x * WALL_JUMP_X
			velocity.y = WALL_JUMP_Y
	else:
		velocity.y += GRAVITY * delta
		velocity.x = lerpf(velocity.x, dir * SPEED, 0.08)

	move_and_slide()
	_update_state()
	queue_redraw()

func _update_state() -> void:
	var prev := state
	if is_on_floor():
		state = State.RUN if absf(velocity.x) > 10 else State.IDLE
	elif is_on_wall_only():
		state = State.WALL_SLIDE
	else:
		state = State.JUMP if velocity.y < 0 else State.FALL
	if state != prev:
		_label.text = State.keys()[state]

func _draw() -> void:
	var colors := {
		State.IDLE:       Color.STEEL_BLUE,
		State.RUN:        Color.DODGER_BLUE,
		State.JUMP:       Color.SKY_BLUE,
		State.FALL:       Color.ORANGE,
		State.WALL_SLIDE: Color.VIOLET,
	}
	draw_rect(Rect2(-13, -26, 26, 50), colors[state])
	draw_rect(Rect2(-6, -22, 5, 5), Color.WHITE)
	draw_rect(Rect2( 1, -22, 5, 5), Color.WHITE)

func _ready() -> void:
	_label.text = State.keys()[state]
