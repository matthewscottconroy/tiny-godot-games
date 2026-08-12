extends Node2D

const COLS := 40
const ROWS := 30
const CELL := 16

var _index_map: PackedByteArray
var _palette: Array[Color]
var _palette_offset: float = 0.0
var _cycle_speed: float = 2.0
var _pattern: int = 0  # 0=water, 1=lava, 2=rainbow

func _ready() -> void:
	_index_map.resize(COLS * ROWS)
	_build_index_map()
	_build_palette()

func _build_index_map() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var idx: int
			match _pattern:
				0:  # water: diagonal waves
					idx = int((col + row * 0.5) * 16.0 / COLS) % 16
				1:  # lava: sin-based noise pattern
					idx = int(sin(col * 0.4) * sin(row * 0.3) * 8.0 + 8.0) % 16
				2:  # rainbow: vertical bands
					idx = (col * 16 / COLS) % 16
				_:
					idx = 0
			_index_map[row * COLS + col] = idx

func _build_palette() -> void:
	_palette.clear()
	match _pattern:
		0:  # water: deep blue → cyan → white → cyan → deep blue (cyclic)
			var stops := [
				Color(0.0, 0.0, 0.35),   # 0  deep blue
				Color(0.0, 0.1, 0.6),    # 1
				Color(0.0, 0.3, 0.8),    # 2
				Color(0.0, 0.55, 0.9),   # 3
				Color(0.1, 0.75, 1.0),   # 4  bright blue
				Color(0.3, 0.88, 1.0),   # 5
				Color(0.6, 0.95, 1.0),   # 6  cyan
				Color(0.85, 1.0, 1.0),   # 7
				Color(1.0, 1.0, 1.0),    # 8  white crest
				Color(0.85, 1.0, 1.0),   # 9
				Color(0.6, 0.95, 1.0),   # 10
				Color(0.3, 0.88, 1.0),   # 11
				Color(0.1, 0.75, 1.0),   # 12
				Color(0.0, 0.55, 0.9),   # 13
				Color(0.0, 0.3, 0.8),    # 14
				Color(0.0, 0.1, 0.6),    # 15
			]
			_palette.assign(stops)
		1:  # lava: black → dark red → orange → yellow → white → back
			var stops := [
				Color(0.0, 0.0, 0.0),    # 0  black
				Color(0.2, 0.0, 0.0),    # 1
				Color(0.4, 0.03, 0.0),   # 2  dark red
				Color(0.6, 0.05, 0.0),   # 3
				Color(0.8, 0.1, 0.0),    # 4  red
				Color(0.9, 0.25, 0.0),   # 5
				Color(1.0, 0.4, 0.0),    # 6  orange
				Color(1.0, 0.6, 0.05),   # 7
				Color(1.0, 0.8, 0.1),    # 8  yellow
				Color(1.0, 0.95, 0.5),   # 9
				Color(1.0, 1.0, 0.9),    # 10 near white
				Color(1.0, 0.95, 0.5),   # 11
				Color(1.0, 0.8, 0.1),    # 12
				Color(1.0, 0.4, 0.0),    # 13
				Color(0.7, 0.1, 0.0),    # 14
				Color(0.3, 0.02, 0.0),   # 15
			]
			_palette.assign(stops)
		2:  # rainbow: full hue rotation
			for i in range(16):
				_palette.append(Color.from_hsv(float(i) / 16.0, 0.9, 1.0))
		_:
			for i in range(16):
				_palette.append(Color.WHITE)

func _process(delta: float) -> void:
	_palette_offset = fmod(_palette_offset + _cycle_speed * delta, 16.0)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_pattern = 0
				_build_index_map()
				_build_palette()
			KEY_L:
				_pattern = 1
				_build_index_map()
				_build_palette()
			KEY_R:
				_pattern = 2
				_build_index_map()
				_build_palette()
			KEY_EQUAL, KEY_PLUS:
				_cycle_speed += 0.5
			KEY_MINUS:
				_cycle_speed = max(0.1, _cycle_speed - 0.5)

func _draw() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var raw_idx: int = _index_map[row * COLS + col]
			var shifted_idx: int = int(raw_idx + _palette_offset) % 16
			draw_rect(
				Rect2(col * CELL, row * CELL, CELL, CELL),
				_palette[shifted_idx]
			)

	# HUD overlay
	var font := ThemeDB.fallback_font
	var bg_rect := Rect2(0, 0, 640, 26)
	draw_rect(bg_rect, Color(0, 0, 0, 0.55))
	var pattern_name: String = ["Water", "Lava", "Rainbow"][_pattern]
	draw_string(font, Vector2(8, 18), "Palette Cycling — Pattern: %s   Speed: %.1f" % [pattern_name, _cycle_speed],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))

	var hint_rect := Rect2(0, 454, 640, 26)
	draw_rect(hint_rect, Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(8, 470), "W: water   L: lava   R: rainbow   +/-: speed",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.9))
