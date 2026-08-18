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
	tick(delta, Input.get_axis("ui_left", "ui_right"),
		Input.is_action_just_pressed("ui_up"),
		is_on_floor(), is_on_wall_only(), get_wall_normal().x)
	move_and_slide()
	queue_redraw()

## One frame of movement, given this frame's input and what the body is touching.
##
## The three cases are genuinely different rules rather than variations on one:
## on the floor the player has full control, on a wall they have none but slide
## slowly, and in the air control comes back gradually.
func tick(delta: float, dir: float, jump_just: bool,
		on_floor: bool, on_wall: bool, wall_normal_x: float) -> void:
	if on_floor:
		velocity.y = 0.0
		velocity.x = dir * SPEED
		if jump_just:
			velocity.y = JUMP_VEL
	elif on_wall:
		# Slide down slowly
		velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE)
		velocity.x = 0.0
		if jump_just:
			# The wall normal already points away from the wall, so the push
			# follows it rather than opposing it.
			velocity.x = wall_normal_x * WALL_JUMP_X
			velocity.y = WALL_JUMP_Y
	else:
		velocity.y += GRAVITY * delta
		velocity.x = lerpf(velocity.x, dir * SPEED, 0.08)

	update_state(on_floor, on_wall)

func update_state(on_floor: bool, on_wall: bool) -> void:
	var prev := state
	if on_floor:
		state = State.RUN if absf(velocity.x) > 10 else State.IDLE
	elif on_wall:
		state = State.WALL_SLIDE
	else:
		state = State.JUMP if velocity.y < 0 else State.FALL
	if state != prev and _label:
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
	# Guarded like the other write: driven outside its scene there is no label,
	# and an assignment to null abandons whatever function it happens in.
	if _label:
		_label.text = State.keys()[state]
