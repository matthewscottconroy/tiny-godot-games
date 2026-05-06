extends Node2D

const STEPS := 16
const NOTES := 8
const CELL_W := 34.0
const CELL_H := 40.0
const GRID_X := 60.0
const GRID_Y := 100.0

# C4 D4 E4 F#4 G4 A4 B4 C5 (pentatonic-ish, full octave)
const FREQUENCIES: Array = [261.63, 293.66, 329.63, 369.99, 392.00, 440.00, 493.88, 523.25]
const NOTE_NAMES: Array = ["C4", "D4", "E4", "F#4", "G4", "A4", "B4", "C5"]

# Row hue colors (bottom = low note, top = high note)
const ROW_COLORS: Array = [
	Color(0.9, 0.3, 0.2),   # C4 — red
	Color(0.9, 0.55, 0.15), # D4 — orange
	Color(0.85, 0.85, 0.1), # E4 — yellow
	Color(0.3, 0.85, 0.3),  # F#4 — green
	Color(0.15, 0.75, 0.85),# G4 — cyan
	Color(0.25, 0.4, 0.95), # A4 — blue
	Color(0.65, 0.25, 0.95),# B4 — violet
	Color(0.9, 0.3, 0.7),   # C5 — pink
]

const NOTE_LEN := 0.12
const SAMPLE_RATE := 44100.0

var _grid: Array = []   # [NOTES][STEPS] bool
var _step: int = 0
var _bpm: float = 120.0
var _step_timer: float = 0.0
var _playing: bool = true

@onready var _player: AudioStreamPlayer = $AudioPlayer
var _stream: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

var _phase: float = 0.0
var _active_freqs: Array = []   # frequencies to mix for current step
var _note_frames_left: int = 0  # frames remaining for current note burst


func _ready() -> void:
	# Set up audio
	_stream = AudioStreamGenerator.new()
	_stream.mix_rate = SAMPLE_RATE
	_stream.buffer_length = 0.1
	_player.stream = _stream
	_player.play()
	_playback = _player.get_stream_playback()

	# Init grid — all false
	_grid = []
	for _n in range(NOTES):
		var row: Array = []
		for _s in range(STEPS):
			row.append(false)
		_grid.append(row)

	# Simple seed pattern
	# Row 0 (C4): beats 0, 4, 8, 12
	for s in [0, 4, 8, 12]:
		_grid[0][s] = true
	# Row 4 (G4): beats 2, 6, 10, 14
	for s in [2, 6, 10, 14]:
		_grid[4][s] = true
	# Row 2 (E4): beats 0, 8
	for s in [0, 8]:
		_grid[2][s] = true
	# Row 7 (C5): step 4, 12
	for s in [4, 12]:
		_grid[7][s] = true


func _get_step_duration() -> float:
	return 60.0 / _bpm * 0.25


func _advance_step() -> void:
	var step_duration := _get_step_duration()
	_step = (_step + 1) % STEPS
	_step_timer = fmod(_step_timer, step_duration)

	# Collect active frequencies for this step
	_active_freqs = []
	for note in range(NOTES):
		if _grid[note][_step]:
			_active_freqs.append(FREQUENCIES[note])

	if _active_freqs.size() > 0:
		_note_frames_left = int(NOTE_LEN * SAMPLE_RATE)
		_phase = 0.0
	else:
		_note_frames_left = 0


func _process(delta: float) -> void:
	# Advance sequencer
	if _playing:
		_step_timer += delta
		var step_duration := _get_step_duration()
		if _step_timer >= step_duration:
			_advance_step()

	# Fill audio buffer
	if _playback != null:
		var available := _playback.get_frames_available()
		for _f in range(available):
			var sample := 0.0
			if _note_frames_left > 0:
				# Mix active frequencies
				var amp := 0.25 / max(1, _active_freqs.size())
				for freq in _active_freqs:
					sample += sin(TAU * freq * _phase / SAMPLE_RATE) * amp
				# Apply a simple decay envelope
				var t := 1.0 - (float(int(NOTE_LEN * SAMPLE_RATE) - _note_frames_left) / (NOTE_LEN * SAMPLE_RATE))
				sample *= t
				_phase += 1.0
				_note_frames_left -= 1
			_playback.push_frame(Vector2(sample, sample))

	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var col := int((mb.position.x - GRID_X) / CELL_W)
			var row := int((mb.position.y - GRID_Y) / CELL_H)
			# Grid is drawn note 0 at bottom, so invert row
			var note := (NOTES - 1) - row
			if col >= 0 and col < STEPS and note >= 0 and note < NOTES:
				_grid[note][col] = !_grid[note][col]

	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed:
			match ke.keycode:
				KEY_SPACE:
					_playing = !_playing
				KEY_EQUAL, KEY_PLUS:
					_bpm = min(240.0, _bpm + 10.0)
				KEY_MINUS:
					_bpm = max(60.0, _bpm - 10.0)
				KEY_C:
					for n in range(NOTES):
						for s in range(STEPS):
							_grid[n][s] = false
					_active_freqs = []
					_note_frames_left = 0


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.07, 0.07, 0.12), true)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(16, 24), "Music Sequencer",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(16, 44),
			"Click cells  |  Space: play/pause  |  +/-: BPM  |  C: clear",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))

	# BPM display
	var bpm_text := "BPM: %d  (+/-)" % int(_bpm)
	draw_string(ThemeDB.fallback_font, Vector2(16, 64), bpm_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(0.85, 0.85, 0.5))

	# Play/pause indicator
	var status_text := "▶ PLAYING" if _playing else "⏸ PAUSED"
	var status_color := Color(0.4, 0.9, 0.4) if _playing else Color(0.9, 0.5, 0.2)
	draw_string(ThemeDB.fallback_font, Vector2(200, 64), status_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)

	# Step numbers at top
	for s in range(STEPS):
		var cx := GRID_X + s * CELL_W + CELL_W * 0.5
		var beat_marker := s % 4 == 0
		var num_color := Color(0.9, 0.9, 0.5) if beat_marker else Color(0.5, 0.5, 0.55)
		draw_string(ThemeDB.fallback_font,
				Vector2(cx - 6, GRID_Y - 6),
				str(s + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, num_color)

	# Grid cells
	for note in range(NOTES):
		var draw_row := (NOTES - 1) - note  # row 0 = top = highest note
		var cell_y := GRID_Y + draw_row * CELL_H

		# Note name label
		draw_string(ThemeDB.fallback_font,
				Vector2(GRID_X - 48, cell_y + CELL_H * 0.65),
				NOTE_NAMES[note], HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
				ROW_COLORS[note])

		for s in range(STEPS):
			var cell_x := GRID_X + s * CELL_W
			var is_active := _grid[note][s]
			var is_current := s == _step

			var bg_color: Color
			if is_active and is_current:
				bg_color = ROW_COLORS[note].lightened(0.4)
			elif is_active:
				bg_color = ROW_COLORS[note]
			elif is_current:
				bg_color = Color(0.25, 0.25, 0.35)
			else:
				bg_color = Color(0.13, 0.13, 0.20)
				if s % 4 == 0:
					bg_color = Color(0.16, 0.16, 0.24)

			draw_rect(Rect2(cell_x + 1, cell_y + 1, CELL_W - 2, CELL_H - 2), bg_color, true)
			draw_rect(Rect2(cell_x, cell_y, CELL_W, CELL_H),
					Color(0.3, 0.3, 0.4, 0.5), false, 1.0)

	# Playhead vertical line
	var ph_x := GRID_X + _step * CELL_W + CELL_W * 0.5
	draw_line(Vector2(ph_x, GRID_Y - 2),
			Vector2(ph_x, GRID_Y + NOTES * CELL_H + 2),
			Color(1.0, 1.0, 0.6, 0.7), 2.0)
