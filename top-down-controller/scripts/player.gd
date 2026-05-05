extends CharacterBody2D

const SPEED := 200.0

var _last_dir := Vector2.RIGHT

@onready var _label: Label = $InfoLabel

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING

func _physics_process(_delta: float) -> void:
	var raw := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dir := raw.normalized() if raw.length() > 0.001 else Vector2.ZERO
	velocity = dir * SPEED
	if dir != Vector2.ZERO:
		_last_dir = dir
	move_and_slide()
	queue_redraw()
	_label.text = "IDLE" if dir == Vector2.ZERO else "%.0f°" % rad_to_deg(_last_dir.angle())

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14, Color.DODGER_BLUE)
	draw_line(Vector2.ZERO, _last_dir * 20.0, Color.WHITE, 3.0)
