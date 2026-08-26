extends CharacterBody2D

const SPEED := 200.0

var _last_dir := Vector2.RIGHT

@onready var _label: Label = $InfoLabel

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING

## Turn a raw input vector into a movement direction.
##
## Normalising is the whole point: without it, holding two keys gives a vector
## of length √2 and diagonal movement is 41% faster than cardinal movement — the
## most common bug in top-down controllers.
func direction_for(raw: Vector2) -> Vector2:
	return raw.normalized() if raw.length() > 0.001 else Vector2.ZERO

## Facing is remembered, so the character keeps pointing where it last moved
## rather than snapping back when input stops.
func update_facing(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		_last_dir = dir

func facing() -> Vector2:
	return _last_dir

func _physics_process(_delta: float) -> void:
	var dir := direction_for(Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	velocity = dir * SPEED
	update_facing(dir)
	move_and_slide()
	queue_redraw()
	if _label:
		_label.text = status_text(dir)

## What the readout says: the heading while moving, IDLE while standing.
##
## It reports `_last_dir` rather than `dir`, so the angle stays on screen when
## the keys are released instead of blinking away — the reader can see which way
## the character is facing while it is still.
func status_text(dir: Vector2) -> String:
	if dir == Vector2.ZERO:
		return "IDLE"
	return "%.0f°" % rad_to_deg(_last_dir.angle())

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14, Color.DODGER_BLUE)
	draw_line(Vector2.ZERO, _last_dir * 20.0, Color.WHITE, 3.0)
