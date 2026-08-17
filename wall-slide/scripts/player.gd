extends CharacterBody2D

const SPEED           := 180.0
const JUMP_VEL        := -380.0
const GRAVITY         := 900.0
const WALL_SLIDE_GRAV := 0.12
const SLIDE_SPEED_CAP := 80.0

var _slide_dist  := 0.0
var _is_sliding  := false

@onready var _label: Label = $InfoLabel

## Is the player pressing INTO the wall it is touching?
##
## `wall_normal` points away from the wall, so pressing into it means the input
## and the normal have opposite signs. Sliding also requires being airborne —
## standing on the floor next to a wall is not a slide.
func should_slide(h: float, on_wall: bool, on_floor: bool, wall_normal_x: float) -> bool:
	if not on_wall or on_floor:
		return false
	return (h * wall_normal_x) < 0.0

## Apply gravity for this frame, reduced and capped while sliding. Returns the
## new vertical velocity; `_slide_dist` accumulates as a side effect.
func tick_vertical(vy: float, delta: float, sliding: bool) -> float:
	var grav_scale := WALL_SLIDE_GRAV if sliding else 1.0
	vy += GRAVITY * grav_scale * delta
	if sliding:
		_slide_dist += absf(vy) * delta
		# The cap is what makes a slide readable: without it the reduced gravity
		# would still accelerate to an unhelpful speed over a tall wall.
		vy = minf(vy, SLIDE_SPEED_CAP)
	return vy

func is_sliding() -> bool:
	return _is_sliding

func slide_distance() -> float:
	return _slide_dist

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var h        := Input.get_axis("ui_left", "ui_right")

	_is_sliding = should_slide(h, is_on_wall(), on_floor,
		get_wall_normal().x if is_on_wall() else 0.0)
	velocity.y = tick_vertical(velocity.y, delta, _is_sliding)
	velocity.x = h * SPEED

	if on_floor and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()

	if _label:
		if _is_sliding:
			_label.text = "SLIDING  %.0f px/s\nTotal: %.0f px" % [velocity.y, _slide_dist]
		else:
			_label.text = "Total slid: %.0f px" % _slide_dist

func _draw() -> void:
	var col := Color.ORANGE if _is_sliding else Color.SANDY_BROWN
	draw_rect(Rect2(-14, -24, 28, 48), col)
	draw_rect(Rect2(-8, -18, 5, 5), Color.WHITE)
	draw_rect(Rect2(3, -18, 5, 5), Color.WHITE)
