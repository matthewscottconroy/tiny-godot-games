extends Node2D

const COLS := 20
const ROWS := 15
const CELL_W := 16.0
const CELL_H := 16.0
const SPRITE_X := 160.0
const SPRITE_Y := 120.0

var _threshold: float = 0.0
var _dissolving: bool = false
var _appearing: bool = false
var _noise_grid: Array[float] = []

func _ready() -> void:
	randomize()
	_noise_grid.resize(COLS * ROWS)
	for i in range(COLS * ROWS):
		_noise_grid[i] = randf()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_D:
				_dissolving = true
				_appearing = false
			KEY_A:
				_appearing = true
				_dissolving = false
			KEY_R:
				_threshold = 0.0
				_dissolving = false
				_appearing = false
				queue_redraw()

func _process(delta: float) -> void:
	if _dissolving and _threshold < 1.0:
		_threshold += delta * 0.6
		if _threshold >= 1.0:
			_threshold = 1.0
			_dissolving = false

	if _appearing and _threshold > 0.0:
		_threshold -= delta * 0.6
		if _threshold <= 0.0:
			_threshold = 0.0
			_appearing = false

	queue_redraw()

func _draw() -> void:
	# Full background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.08, 0.12))

	# Grid background (behind cells)
	var grid_w: float = COLS * CELL_W
	var grid_h: float = ROWS * CELL_H
	draw_rect(Rect2(SPRITE_X - 2, SPRITE_Y - 2, grid_w + 4, grid_h + 4), Color(0.05, 0.05, 0.1))

	var base_color := Color(0.2, 0.6, 1.0)
	var edge_color := Color(1.0, 0.6, 0.0)

	for row in range(ROWS):
		for col in range(COLS):
			var cell_noise: float = _noise_grid[row * COLS + col]
			if cell_noise > _threshold:
				# Determine cell color
				var cell_color: Color
				var dist_to_edge: float = abs(cell_noise - _threshold)
				if dist_to_edge < 0.1:
					# Edge glow: lerp from edge_color to base_color
					var t: float = dist_to_edge / 0.1
					cell_color = edge_color.lerp(base_color, t)
				else:
					cell_color = base_color

				var cell_x: float = SPRITE_X + col * CELL_W + 1.0
				var cell_y: float = SPRITE_Y + row * CELL_H + 1.0
				draw_rect(Rect2(cell_x, cell_y, CELL_W - 2.0, CELL_H - 2.0), cell_color)

	# Threshold bar background
	var bar_y: float = 400.0
	draw_rect(Rect2(80, bar_y, 480, 16), Color(0.2, 0.2, 0.3))
	# Threshold bar fill
	var bar_fill_w: float = 480.0 * _threshold
	draw_rect(Rect2(80, bar_y, bar_fill_w, 16), Color(1.0, 0.6, 0.0))
	# Bar border
	draw_rect(Rect2(80, bar_y, 480, 16), Color(0.5, 0.5, 0.6), false)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(10, 24), "Dissolve Effect", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 1.0, 1.0))

	# Hints
	draw_string(ThemeDB.fallback_font, Vector2(10, 440), "D: dissolve   A: appear   R: reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8))

	# Threshold label
	var pct: int = int(_threshold * 100.0)
	draw_string(ThemeDB.fallback_font, Vector2(80, bar_y - 6), "Dissolved: %d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.7, 0.3))

	# State label
	var state_str: String = ""
	if _dissolving:
		state_str = "DISSOLVING..."
	elif _appearing:
		state_str = "APPEARING..."
	elif _threshold >= 1.0:
		state_str = "FULLY DISSOLVED"
	elif _threshold <= 0.0:
		state_str = "FULLY VISIBLE"
	if state_str != "":
		draw_string(ThemeDB.fallback_font, Vector2(400, bar_y - 6), state_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.9, 0.5))
