extends Control

# size-exempt: the point is a settings screen wired end to end; a partial one would not demonstrate persistence

const CONFIG_PATH := "user://settings.cfg"

const DEFAULTS := {
	"master_volume": 80,
	"sfx_volume":    60,
	"fullscreen":    false,
	"player_speed":  150,
	"show_fps":      true,
}

# Panel geometry
const PANEL_W := 480.0
const PANEL_H := 380.0
const PANEL_X := 80.0
const PANEL_Y := 50.0

# Row layout inside panel
const ROW_START_Y := 80.0
const ROW_HEIGHT := 54.0
const LABEL_X := 20.0
const CTRL_X := 210.0
const SLIDER_W := 220.0
const SLIDER_H := 22.0
const TOGGLE_W := 60.0
const TOGGLE_H := 28.0

# Save button
const SAVE_RECT := Rect2(PANEL_X + PANEL_W / 2 - 60, PANEL_Y + PANEL_H - 52, 120, 36)

var _settings: Dictionary = {}
var _hovered_control: String = ""
var _dragging: String = ""
var _saved_flash: float = 0.0
var _dirty: bool = false


func _ready() -> void:
	_settings = DEFAULTS.duplicate()
	_load_settings()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err == OK:
		_settings["master_volume"] = int(cfg.get_value("audio",    "master_volume", DEFAULTS["master_volume"]))
		_settings["sfx_volume"]    = int(cfg.get_value("audio",    "sfx_volume",    DEFAULTS["sfx_volume"]))
		_settings["fullscreen"]    = bool(cfg.get_value("display",  "fullscreen",    DEFAULTS["fullscreen"]))
		_settings["player_speed"]  = int(cfg.get_value("gameplay", "player_speed",  DEFAULTS["player_speed"]))
		_settings["show_fps"]      = bool(cfg.get_value("gameplay", "show_fps",     DEFAULTS["show_fps"]))
	_clamp_all()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio",    "master_volume", _settings["master_volume"])
	cfg.set_value("audio",    "sfx_volume",    _settings["sfx_volume"])
	cfg.set_value("display",  "fullscreen",    _settings["fullscreen"])
	cfg.set_value("gameplay", "player_speed",  _settings["player_speed"])
	cfg.set_value("gameplay", "show_fps",      _settings["show_fps"])
	cfg.save(CONFIG_PATH)
	_saved_flash = 1.5
	_dirty = false


func _clamp_all() -> void:
	_settings["master_volume"] = clampi(int(_settings["master_volume"]), 0, 100)
	_settings["sfx_volume"]    = clampi(int(_settings["sfx_volume"]),    0, 100)
	_settings["player_speed"]  = clampi(int(_settings["player_speed"]),  50, 300)


func _get_slider_rect(row: int) -> Rect2:
	var y := PANEL_Y + ROW_START_Y + row * ROW_HEIGHT
	return Rect2(PANEL_X + CTRL_X, y + (ROW_HEIGHT - SLIDER_H) / 2.0, SLIDER_W, SLIDER_H)


func _get_toggle_rect(row: int) -> Rect2:
	var y := PANEL_Y + ROW_START_Y + row * ROW_HEIGHT
	return Rect2(PANEL_X + CTRL_X, y + (ROW_HEIGHT - TOGGLE_H) / 2.0, TOGGLE_W, TOGGLE_H)


func _slider_value_from_x(rect: Rect2, mouse_x: float, min_val: int, max_val: int) -> int:
	var frac := clampf((mouse_x - rect.position.x) / rect.size.x, 0.0, 1.0)
	return int(round(min_val + frac * (max_val - min_val)))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_hovered_control = _hit_test(mm.position)
		# Handle dragging
		if _dragging != "":
			_apply_drag(mm.position)
		queue_redraw()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# Save button
				if SAVE_RECT.has_point(mb.position):
					_save_settings()
					queue_redraw()
					return
				# Row 0: master_volume slider
				if _get_slider_rect(0).has_point(mb.position):
					_dragging = "master_volume"
					_apply_drag(mb.position)
				# Row 1: sfx_volume slider
				elif _get_slider_rect(1).has_point(mb.position):
					_dragging = "sfx_volume"
					_apply_drag(mb.position)
				# Row 2: fullscreen toggle
				elif _get_toggle_rect(2).has_point(mb.position):
					_settings["fullscreen"] = not bool(_settings["fullscreen"])
					_dirty = true
					queue_redraw()
				# Row 3: player_speed slider
				elif _get_slider_rect(3).has_point(mb.position):
					_dragging = "player_speed"
					_apply_drag(mb.position)
				# Row 4: show_fps toggle
				elif _get_toggle_rect(4).has_point(mb.position):
					_settings["show_fps"] = not bool(_settings["show_fps"])
					_dirty = true
					queue_redraw()
			else:
				# Release
				if _dragging != "":
					_save_settings()
				_dragging = ""


func _apply_drag(mouse_pos: Vector2) -> void:
	match _dragging:
		"master_volume":
			_settings["master_volume"] = _slider_value_from_x(_get_slider_rect(0), mouse_pos.x, 0, 100)
			_dirty = true
		"sfx_volume":
			_settings["sfx_volume"] = _slider_value_from_x(_get_slider_rect(1), mouse_pos.x, 0, 100)
			_dirty = true
		"player_speed":
			_settings["player_speed"] = _slider_value_from_x(_get_slider_rect(3), mouse_pos.x, 50, 300)
			_dirty = true
	queue_redraw()


func _hit_test(pos: Vector2) -> String:
	if _get_slider_rect(0).has_point(pos): return "master_volume"
	if _get_slider_rect(1).has_point(pos): return "sfx_volume"
	if _get_toggle_rect(2).has_point(pos): return "fullscreen"
	if _get_slider_rect(3).has_point(pos): return "player_speed"
	if _get_toggle_rect(4).has_point(pos): return "show_fps"
	if SAVE_RECT.has_point(pos):           return "save"
	return ""


func _process(delta: float) -> void:
	if _saved_flash > 0.0:
		_saved_flash = maxf(0.0, _saved_flash - delta)
		queue_redraw()


func _draw_slider(row: int, key: String, min_val: int, max_val: int) -> void:
	var rect := _get_slider_rect(row)
	var val := int(_settings[key])
	var frac := clampf(float(val - min_val) / float(max_val - min_val), 0.0, 1.0)
	var hovered := _hovered_control == key or _dragging == key

	# Track background
	draw_rect(rect, Color(0.15, 0.15, 0.25))
	# Fill
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * frac, rect.size.y)), Color(0.3, 0.6, 0.9))
	# Outline
	draw_rect(rect, Color(0.5, 0.6, 0.8) if hovered else Color(0.3, 0.35, 0.5), false, 1.5)
	# Knob
	var knob_x := rect.position.x + rect.size.x * frac
	var knob_cy := rect.position.y + rect.size.y / 2.0
	draw_circle(Vector2(knob_x, knob_cy), 9.0, Color(0.9, 0.9, 1.0) if hovered else Color(0.7, 0.7, 0.85))
	# Value text
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x + 8, 16),
		str(val), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 1.0))


func _draw_toggle(row: int, key: String) -> void:
	var rect := _get_toggle_rect(row)
	var on := bool(_settings[key])
	var hovered := _hovered_control == key

	# Background
	draw_rect(rect, Color(0.2, 0.55, 0.2) if on else Color(0.2, 0.2, 0.28))
	draw_rect(rect, Color(0.4, 0.9, 0.4) if (on and hovered) else (Color(0.3, 0.8, 0.3) if on else (Color(0.5, 0.5, 0.6) if hovered else Color(0.3, 0.3, 0.4))), false, 2.0)

	# Knob circle
	var knob_x := rect.position.x + (rect.size.x - 14) if on else rect.position.x + 14
	var knob_cy := rect.position.y + rect.size.y / 2.0
	draw_circle(Vector2(knob_x, knob_cy), 10.0, Color(1, 1, 1) if on else Color(0.6, 0.6, 0.65))

	# ON / OFF text
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x + 8, 20),
		"ON" if on else "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(0.4, 1.0, 0.4) if on else Color(0.6, 0.6, 0.6))


func _draw() -> void:
	# Full background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.05, 0.05, 0.10))

	# Panel
	draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), Color(0.10, 0.10, 0.18))
	draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), Color(0.35, 0.35, 0.55), false, 2.0)

	# Panel title
	draw_string(ThemeDB.fallback_font, Vector2(PANEL_X + 20, PANEL_Y + 40),
		"Settings", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.95, 0.9, 1.0))
	draw_line(Vector2(PANEL_X + 10, PANEL_Y + 50), Vector2(PANEL_X + PANEL_W - 10, PANEL_Y + 50),
		Color(0.3, 0.3, 0.5), 1.0)

	# Row labels
	var labels := ["Master Volume", "SFX Volume", "Fullscreen", "Player Speed", "Show FPS"]
	for i in labels.size():
		var row_y := PANEL_Y + ROW_START_Y + i * ROW_HEIGHT + ROW_HEIGHT / 2.0 + 6
		draw_string(ThemeDB.fallback_font, Vector2(PANEL_X + LABEL_X, row_y),
			labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.8, 0.8, 0.95))

	# Row 0: master_volume slider (0-100)
	_draw_slider(0, "master_volume", 0, 100)
	# Row 1: sfx_volume slider (0-100)
	_draw_slider(1, "sfx_volume", 0, 100)
	# Row 2: fullscreen toggle
	_draw_toggle(2, "fullscreen")
	# Row 3: player_speed slider (50-300)
	_draw_slider(3, "player_speed", 50, 300)
	# Row 4: show_fps toggle
	_draw_toggle(4, "show_fps")

	# Save button
	var save_hovered := _hovered_control == "save"
	draw_rect(SAVE_RECT, Color(0.25, 0.5, 0.25) if save_hovered else Color(0.18, 0.38, 0.18))
	draw_rect(SAVE_RECT, Color(0.5, 0.9, 0.5) if save_hovered else Color(0.35, 0.6, 0.35), false, 2.0)
	draw_string(ThemeDB.fallback_font, SAVE_RECT.position + Vector2(28, 24),
		"Save", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1))

	# Saved flash
	if _saved_flash > 0.0:
		var alpha := clampf(_saved_flash / 1.5, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font,
			SAVE_RECT.position + Vector2(130, 24),
			"Saved!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.4, 1.0, 0.4, alpha))

	# Config path display
	draw_string(ThemeDB.fallback_font, Vector2(PANEL_X + 10, PANEL_Y + PANEL_H + 24),
		"Saved to: " + CONFIG_PATH, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.5, 0.65))

	# Hints
	draw_string(ThemeDB.fallback_font, Vector2(PANEL_X + 10, PANEL_Y + PANEL_H + 44),
		"Click sliders to adjust   Click toggles to switch",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.5, 0.6))
