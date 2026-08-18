extends Node2D

const SPEED   := 180.0
const GRAVITY := 900.0
const JUMP_VEL := -400.0

var _player_pos  := Vector2(80.0, 200.0)
var _vel         := Vector2.ZERO
var _on_floor    := false
var _in_water    := false
var _wave_offset := 0.0

@onready var _water:     ColorRect = $Water
@onready var _water_mat: ShaderMaterial = $Water.material
@onready var _hud:       CanvasLayer = $HUD

const WATER_Y := 260.0

func _ready() -> void:
	$HUD/SpeedRow/SpeedSlider.value_changed.connect(func(v: float) -> void:
		_water_mat.set_shader_parameter("wave_speed", v)
	)
	$HUD/AmpRow/AmpSlider.value_changed.connect(func(v: float) -> void:
		_water_mat.set_shader_parameter("wave_amplitude", v)
	)
	$HUD/SpeedRow/SpeedSlider.value = 1.2
	$HUD/AmpRow/AmpSlider.value   = 0.018

func _physics_process(delta: float) -> void:
	tick(delta, Input.get_axis("ui_left", "ui_right"),
		Input.is_action_just_pressed("ui_up"))
	queue_redraw()

## One step of swimming or walking, given this frame's input.
##
## Water changes four things at once — gravity, top speed, how high a jump
## goes, and how quickly you slow down — which is what makes going under feel
## different rather than just look different.
func tick(delta: float, move_axis: float, jump_pressed: bool) -> void:
	_in_water = _player_pos.y + 14 > WATER_Y

	if not _on_floor:
		var grav := GRAVITY * (0.2 if _in_water else 1.0)
		_vel.y += grav * delta

	var speed := SPEED * (0.4 if _in_water else 1.0)
	_vel.x = move_axis * speed

	if _on_floor and jump_pressed:
		_vel.y = JUMP_VEL
	if _in_water and jump_pressed:
		_vel.y = JUMP_VEL * 0.55  # swim up

	_player_pos += _vel * delta

	# Floor at y=460
	if _player_pos.y >= 460.0:
		_player_pos.y = 460.0
		_vel.y = 0.0
		_on_floor = true
	else:
		_on_floor = false

	_player_pos.x = clampf(_player_pos.x, 14, 626)

	if _in_water:
		_vel *= 0.85  # water drag

func _draw() -> void:
	# Sky
	draw_rect(Rect2(0, 0, 640, WATER_Y), Color(0.6, 0.8, 1.0))
	# Underwater floor
	draw_rect(Rect2(0, WATER_Y, 640, 480 - WATER_Y), Color(0.1, 0.2, 0.4))
	# Ground
	draw_rect(Rect2(0, 460, 640, 20), Color(0.3, 0.5, 0.2))

	# Platforms
	for px in [120, 320, 520]:
		draw_rect(Rect2(px - 50, 350, 100, 12), Color(0.35, 0.25, 0.15))

	# Player
	var col := Color(0.2, 0.6, 1.0) if _in_water else Color(0.9, 0.6, 0.1)
	draw_circle(_player_pos, 14, col)
	draw_circle(_player_pos, 10, col.lightened(0.3))
	draw_circle(_player_pos, 4, Color.WHITE)
