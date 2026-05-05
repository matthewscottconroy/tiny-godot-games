extends Node2D

const DAY_LENGTH   := 30.0  # seconds per full cycle
const SPEED_FACTOR := 1.0   # multiplied by UI speed slider

# Time-of-day keyframes: [normalized_time, sky_color, modulate_color]
const KEYFRAMES: Array = [
	[0.00, Color(0.05, 0.05, 0.20), Color(0.12, 0.14, 0.30)],  # midnight
	[0.20, Color(0.20, 0.15, 0.30), Color(0.35, 0.28, 0.55)],  # pre-dawn
	[0.25, Color(0.70, 0.40, 0.20), Color(0.80, 0.65, 0.50)],  # dawn
	[0.35, Color(0.50, 0.70, 1.00), Color(1.00, 0.95, 0.85)],  # morning
	[0.50, Color(0.45, 0.68, 1.00), Color(1.00, 1.00, 1.00)],  # noon
	[0.65, Color(0.45, 0.65, 0.95), Color(1.00, 0.98, 0.90)],  # afternoon
	[0.75, Color(0.80, 0.45, 0.10), Color(0.90, 0.70, 0.50)],  # dusk
	[0.85, Color(0.20, 0.10, 0.25), Color(0.40, 0.30, 0.55)],  # twilight
	[1.00, Color(0.05, 0.05, 0.20), Color(0.12, 0.14, 0.30)],  # midnight (loop)
]

var _time     := 0.0  # 0..1 normalized
var _speed    := 1.0

@onready var _canvas_mod: CanvasModulate = $CanvasModulate
@onready var _time_label: Label          = $HUD/TimeLabel
@onready var _hint_label: Label          = $HUD/HintLabel

func _ready() -> void:
	$HUD/SlowBtn.pressed.connect(func() -> void: _speed = 0.5)
	$HUD/NormalBtn.pressed.connect(func() -> void: _speed = 1.0)
	$HUD/FastBtn.pressed.connect(func() -> void: _speed = 4.0)

func _process(delta: float) -> void:
	_time = fmod(_time + delta * _speed / DAY_LENGTH, 1.0)
	var sky_col := _lerp_keyframes(_time, 0)
	var mod_col := _lerp_keyframes(_time, 1)
	_canvas_mod.color = mod_col
	_time_label.text  = _time_name(_time)
	queue_redraw()

func _lerp_keyframes(t: float, col_idx: int) -> Color:
	for i in KEYFRAMES.size() - 1:
		var t0: float = KEYFRAMES[i][0]
		var t1: float = KEYFRAMES[i + 1][0]
		if t >= t0 and t <= t1:
			var local := (t - t0) / (t1 - t0)
			var c0: Color = KEYFRAMES[i][col_idx + 1]
			var c1: Color = KEYFRAMES[i + 1][col_idx + 1]
			return c0.lerp(c1, local)
	return KEYFRAMES[0][col_idx + 1]

func _time_name(t: float) -> String:
	var h := int(t * 24)
	var m := int(fmod(t * 24, 1.0) * 60)
	var period := "noon" if h == 12 else ("midnight" if h == 0 or h == 24 else ("PM" if h > 12 else "AM"))
	var display_h := h if h <= 12 else h - 12
	if display_h == 0:
		display_h = 12
	return "%02d:%02d %s" % [display_h, m, period]

func _draw() -> void:
	var sky := _lerp_keyframes(_time, 0)
	# Sky background
	draw_rect(Rect2(0, 0, 640, 340), sky)

	# Ground
	var night_ratio := 1.0 - _canvas_mod.color.get_luminance()
	var ground_col  := Color(0.15, 0.35, 0.10).darkened(night_ratio * 0.7)
	draw_rect(Rect2(0, 340, 640, 140), ground_col)

	# Sun arc
	var sun_angle := (_time - 0.25) * TAU  # 0.25=dawn rises, 0.75=dusk sets
	var sun_x     := 320 + cos(sun_angle) * 260
	var sun_y     := 340 - sin(sun_angle) * 280
	if sin(sun_angle) > 0:
		var sun_brightness := sinf(sun_angle * 0.5 + 0.1)
		draw_circle(Vector2(sun_x, sun_y), 24, Color(1.0, 0.95, 0.3, sun_brightness))

	# Moon arc (opposite)
	var moon_angle := sun_angle + PI
	var moon_x     := 320 + cos(moon_angle) * 260
	var moon_y     := 340 - sin(moon_angle) * 280
	if sin(moon_angle) > 0:
		draw_circle(Vector2(moon_x, moon_y), 16, Color(0.95, 0.95, 1.0, 0.85))

	# Stars (visible at night)
	var star_alpha := clampf(1.0 - _canvas_mod.color.get_luminance() * 2.5, 0.0, 1.0)
	if star_alpha > 0.02:
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345
		for i in 60:
			var sx := rng.randf_range(0, 640)
			var sy := rng.randf_range(0, 320)
			draw_circle(Vector2(sx, sy), rng.randf_range(0.8, 2.0), Color(1, 1, 1, star_alpha))

	# Trees
	for tx in [80, 180, 320, 460, 560]:
		_draw_tree(tx, 340)

func _draw_tree(x: float, ground_y: float) -> void:
	draw_rect(Rect2(x - 5, ground_y - 60, 10, 60), Color(0.3, 0.2, 0.1))
	draw_circle(Vector2(x, ground_y - 70), 28, Color(0.1, 0.4, 0.1))
	draw_circle(Vector2(x - 12, ground_y - 55), 18, Color(0.1, 0.38, 0.1))
	draw_circle(Vector2(x + 14, ground_y - 52), 16, Color(0.12, 0.42, 0.1))
