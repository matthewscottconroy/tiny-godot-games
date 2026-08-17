extends Node2D

const COLS := 128
const TERRAIN_TOP := 80.0
const TERRAIN_BOTTOM := 460.0

var _heights: Array = []  # Array of floats, length = COLS
var _noise := FastNoiseLite.new()
var _freq := 0.02
var _octaves := 4

@onready var _freq_label: Label = $HUD/FreqLabel
@onready var _oct_label: Label = $HUD/OctLabel


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_update_noise()


func _regen() -> void:
	_heights.clear()
	for i in COLS:
		# Sampled at the column index, not at index * _freq: the frequency is
		# already set on the noise itself, and applying it twice squashed the
		# default terrain to about four pixels of relief.
		var h := (_noise.get_noise_1d(float(i)) + 1.0) * 0.5
		_heights.append(lerpf(TERRAIN_BOTTOM, TERRAIN_TOP, h))
	queue_redraw()
	_refresh_labels()


func _update_noise() -> void:
	_noise.frequency = _freq
	_noise.fractal_octaves = _octaves
	_regen()


func _refresh_labels() -> void:
	if _freq_label:
		_freq_label.text = "Frequency: %.3f" % _freq
	if _oct_label:
		_oct_label.text = "Octaves: %d" % _octaves


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		_noise.seed = randi()
		_update_noise()

	apply_controls(
		Input.is_key_pressed(KEY_F), Input.is_key_pressed(KEY_G),
		Input.is_key_pressed(KEY_O), Input.is_key_pressed(KEY_P))

## Nudge the settings by one frame's worth of held keys.
##
## The terrain is only rebuilt when something actually changed: regenerating
## 128 noise samples every frame to arrive at the same heights is wasted work,
## and it is the kind of waste that hides in a demo this small.
func apply_controls(freq_up: bool, freq_down: bool, oct_up: bool, oct_down: bool) -> void:
	var changed := false

	if freq_up:
		_freq = clampf(_freq + 0.001, 0.001, 0.2)
		changed = true
	if freq_down:
		_freq = clampf(_freq - 0.001, 0.001, 0.2)
		changed = true
	if oct_up:
		_octaves = clampi(_octaves + 1, 1, 8)
		changed = true
	if oct_down:
		_octaves = clampi(_octaves - 1, 1, 8)
		changed = true

	if changed:
		_update_noise()


func _draw() -> void:
	if _heights.is_empty():
		return

	# Sky background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.18, 0.38, 0.65))

	# Subtle sky gradient bands
	for band in 6:
		var band_y := float(band) * 60.0
		var alpha := 0.04 * (6 - band)
		draw_rect(Rect2(0, band_y, 640, 60), Color(0.05, 0.05, 0.2, alpha))

	# Build terrain polygon
	var pts := PackedVector2Array()
	pts.append(Vector2(0.0, 480.0))  # bottom-left
	for i in COLS:
		pts.append(Vector2(float(i) / float(COLS - 1) * 640.0, _heights[i]))
	pts.append(Vector2(640.0, 480.0))  # bottom-right

	draw_polygon(pts, PackedColorArray([Color(0.18, 0.52, 0.18)]))

	# Darker rocky layer beneath the surface line
	var rock_pts := PackedVector2Array()
	rock_pts.append(Vector2(0.0, 480.0))
	for i in COLS:
		rock_pts.append(Vector2(float(i) / float(COLS - 1) * 640.0, _heights[i] + 20.0))
	rock_pts.append(Vector2(640.0, 480.0))
	draw_polygon(rock_pts, PackedColorArray([Color(0.28, 0.20, 0.12)]))

	# Surface outline (darker green edge)
	for i in range(COLS - 1):
		var x0 := float(i) / float(COLS - 1) * 640.0
		var x1 := float(i + 1) / float(COLS - 1) * 640.0
		draw_line(Vector2(x0, _heights[i]), Vector2(x1, _heights[i + 1]),
				Color(0.1, 0.38, 0.1), 2.0)

	# UI overlay panel at top
	draw_rect(Rect2(0, 0, 640, 44), Color(0.0, 0.0, 0.0, 0.55))
	draw_line(Vector2(0, 44), Vector2(640, 44), Color(0.3, 0.5, 0.3), 1)
	draw_string(ThemeDB.fallback_font, Vector2(10, 28),
			"R=new seed   F/G=freq +/-   O/P=octaves +/-",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.95, 0.85))

	# Stats panel (bottom-right)
	draw_rect(Rect2(460, 448, 178, 30), Color(0.0, 0.0, 0.0, 0.50))
	draw_string(ThemeDB.fallback_font, Vector2(466, 468),
			"Freq: %.3f   Oct: %d" % [_freq, _octaves],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 1.0, 0.9))
