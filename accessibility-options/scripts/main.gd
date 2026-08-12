extends Node2D

# Demo driver. A tiny scene that responds to every setting at once, so the
# effect of each is visible immediately rather than described.

@onready var _settings: AccessibilitySettings = $Settings
@onready var _status: Label = $HUD/StatusLabel
@onready var _hint: Label = $HUD/HintLabel

var _shake_time := 0.0
var _shake_offset := Vector2.ZERO
var _bars := [0.8, 0.35, 0.6]      # positive / negative / neutral samples

func _ready() -> void:
	_settings.changed.connect(_refresh)
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_C: _settings.cycle_palette()
		KEY_M: _settings.reduced_motion = not _settings.reduced_motion
		KEY_S: _settings.shape_cues = not _settings.shape_cues
		KEY_EQUAL, KEY_KP_ADD: _settings.text_scale += 0.25
		KEY_MINUS, KEY_KP_SUBTRACT: _settings.text_scale -= 0.25
		KEY_SPACE: _kick()

func _kick() -> void:
	# Decorative motion: skipped entirely under reduced motion.
	_shake_time = _settings.motion_duration(0.4)

func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time = maxf(_shake_time - delta, 0.0)
		_shake_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6)) * (_shake_time / 0.4)
	else:
		_shake_offset = Vector2.ZERO
	queue_redraw()

func _refresh() -> void:
	var size := _settings.font_size(14)
	_status.add_theme_font_size_override("font_size", size)
	_hint.add_theme_font_size_override("font_size", size)
	_status.text = "Palette: %s    Reduced motion: %s    Shape cues: %s    Text: %.2fx" % [
		_settings.palette_name(),
		"on" if _settings.reduced_motion else "off",
		"on" if _settings.shape_cues else "off",
		_settings.text_scale,
	]
	_hint.text = "C palette   M reduced motion   S shape cues   +/- text size   Space shake"
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	var c := _settings.colors()
	var labels := ["Healing", "Damage", "Neutral"]
	var keys := ["positive", "negative", "neutral"]
	var font := ThemeDB.fallback_font
	var fs := _settings.font_size(15)

	for i in 3:
		var y := 150.0 + i * 80.0 + _shake_offset.y
		var col: Color = c[keys[i]]
		var w: float = 380.0 * float(_bars[i])
		draw_rect(Rect2(140 + _shake_offset.x, y, 380, 40), Color(0.16, 0.17, 0.22))
		draw_rect(Rect2(140 + _shake_offset.x, y, w, 40), col)
		# A shape cue carries the same meaning as the colour, for players who
		# cannot rely on hue alone.
		var cue := _settings.cue_for(i == 0)
		var text: String = labels[i] + ("  " + cue if cue != "" and i != 2 else "")
		draw_string(font, Vector2(150 + _shake_offset.x, y + 27), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.05, 0.05, 0.08))
