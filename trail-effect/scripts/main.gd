extends Node2D

const SPEED      := 200.0
const JUMP_VEL   := -420.0
const GRAVITY    := 900.0
const MAX_POINTS := 50

var _velocity := Vector2.ZERO
var _pos      := Vector2(320.0, 400.0)
var _on_floor := false
var _trail_len := MAX_POINTS

@onready var _trail: Line2D = $Trail
@onready var _len_label: Label = $HUD/LenLabel

func _ready() -> void:
	_setup_trail()
	$HUD/BtnRow/LongerBtn.pressed.connect(func() -> void:
		_trail_len = mini(_trail_len + 10, 120)
		_update_gradient()
	)
	$HUD/BtnRow/ShorterBtn.pressed.connect(func() -> void:
		_trail_len = maxi(_trail_len - 10, 5)
	)

func _setup_trail() -> void:
	_trail.width = 8.0
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode   = Line2D.LINE_CAP_ROUND
	_update_gradient()

func _update_gradient() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.1, 0.0))   # tail: transparent
	grad.set_color(1, Color(1.0, 0.85, 0.1, 1.0))   # head: opaque gold
	_trail.gradient = grad
	_len_label.text = "Trail length: %d points" % _trail_len

func _physics_process(delta: float) -> void:
	# Simple kinematic movement (not using CharacterBody2D to keep demo minimal)
	var dir := Input.get_axis("ui_left", "ui_right")
	_velocity.x = dir * SPEED

	if not _on_floor:
		_velocity.y += GRAVITY * delta

	_pos += _velocity * delta

	# Floor at y=440
	if _pos.y >= 440.0:
		_pos.y   = 440.0
		_velocity.y = 0.0
		_on_floor = true
	else:
		_on_floor = false

	# Clamp to screen
	_pos.x = clampf(_pos.x, 16, 624)

	if _on_floor and Input.is_action_just_pressed("ui_up"):
		_velocity.y = JUMP_VEL

	_update_trail()
	queue_redraw()

func _update_trail() -> void:
	_trail.add_point(_pos, 0)  # insert at front
	while _trail.get_point_count() > _trail_len:
		_trail.remove_point(_trail.get_point_count() - 1)  # remove tail

func _draw() -> void:
	# Player body
	draw_circle(_pos, 14, Color(1.0, 0.85, 0.1))
	draw_circle(_pos, 10, Color(1.0, 1.0, 0.6))
	draw_circle(_pos, 4, Color.WHITE)

	# Floor line
	draw_line(Vector2(0, 440), Vector2(640, 440), Color(0.3, 0.4, 0.5), 3.0)

	# Platforms
	draw_rect(Rect2(140, 340, 140, 10), Color(0.3, 0.4, 0.5))
	draw_rect(Rect2(360, 260, 100, 10), Color(0.3, 0.4, 0.5))
	draw_rect(Rect2(240, 180, 80, 10), Color(0.3, 0.4, 0.5))
