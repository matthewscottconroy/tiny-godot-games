extends CharacterBody2D

const SPEED           := 180.0
const JUMP_VEL        := -380.0
const GRAVITY         := 900.0
const WALL_SLIDE_GRAV := 0.12
const SLIDE_SPEED_CAP := 80.0

var _slide_dist  := 0.0
var _is_sliding  := false

@onready var _label: Label = $InfoLabel

func _physics_process(delta: float) -> void:
	var on_wall  := is_on_wall()
	var on_floor := is_on_floor()
	var h        := Input.get_axis("ui_left", "ui_right")

	_is_sliding = false
	if on_wall and not on_floor:
		var wn := get_wall_normal()
		if (h * wn.x) < 0.0:
			_is_sliding = true

	var grav_scale := WALL_SLIDE_GRAV if _is_sliding else 1.0
	velocity.y += GRAVITY * grav_scale * delta

	if _is_sliding:
		_slide_dist += absf(velocity.y) * delta
		velocity.y = minf(velocity.y, SLIDE_SPEED_CAP)

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
