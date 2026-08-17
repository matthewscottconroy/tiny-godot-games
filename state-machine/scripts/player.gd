extends CharacterBody2D

enum State { IDLE, WALK, JUMP, FALL }

## Emitted whenever the derived state changes. Other systems — an
## AnimationPlayer, an audio manager, a UI — can react to transitions without
## polling `state` every frame. This is the FSM's reuse hook.
signal state_changed(new_state: State)

@export var speed := 200.0
@export var jump_velocity := -420.0
@export var gravity := 900.0
## Horizontal speed (px/s) above which a grounded character counts as WALK.
@export var walk_threshold := 10.0

var state := State.IDLE

@onready var state_label: Label = $StateLabel

func _draw() -> void:
	var color: Color = {
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
	velocity.x = dir * speed
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_velocity
	move_and_slide()
	_transition()
	queue_redraw()

## The whole state machine: derive the state from physics rather than tracking
## it with flags. Taking its inputs as parameters keeps it a pure function of
## the body's motion, which is both the lesson and what makes it testable.
func state_for(on_floor: bool, vel: Vector2) -> State:
	if on_floor:
		# Below the threshold counts as idle, so tiny residual drift after
		# stopping does not read as walking.
		return State.WALK if absf(vel.x) > walk_threshold else State.IDLE
	# Airborne: rising is a jump, descending is a fall.
	return State.JUMP if vel.y < 0 else State.FALL

func _transition() -> void:
	var prev := state
	state = state_for(is_on_floor(), velocity)
	if state != prev:
		if state_label:
			state_label.text = State.keys()[state]
		state_changed.emit(state)

func _ready() -> void:
	if state_label:
		state_label.text = State.keys()[state]
