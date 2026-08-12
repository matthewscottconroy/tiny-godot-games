extends Node2D

const MIX_RATE := 44100.0
const WAVEFORM_SAMPLES := 256

@onready var _player: AudioStreamPlayer = $SFXPlayer

var _generating := false
var _gen_phase := 0.0
var _gen_frames := 0
var _gen_total := 0
var _gen_type := ""

# Ring buffer for waveform visualization
var _wave_buf: Array = []
var _wave_head := 0


func _ready() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.1
	_player.stream = stream
	_player.play()
	_wave_buf.resize(WAVEFORM_SAMPLES)
	_wave_buf.fill(0.0)


func _process(_delta: float) -> void:
	# --- Key input ---
	if Input.is_key_pressed(KEY_1):
		_start_sfx("beep")
	elif Input.is_key_pressed(KEY_2):
		_start_sfx("buzz")
	elif Input.is_key_pressed(KEY_3):
		_start_sfx("crash")
	elif Input.is_key_pressed(KEY_4):
		_start_sfx("chirp")

	# --- Fill buffer ---
	var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		var n := pb.get_frames_available()
		for i in n:
			if _gen_frames >= _gen_total:
				pb.push_frame(Vector2.ZERO)
				# Still record silence in ring buffer
				_wave_buf[_wave_head] = 0.0
				_wave_head = (_wave_head + 1) % WAVEFORM_SAMPLES
				continue
			var t := float(_gen_frames) / float(_gen_total)
			var s := _get_sample(t)
			pb.push_frame(Vector2(s, s) * 0.5)
			_wave_buf[_wave_head] = s * 0.5
			_wave_head = (_wave_head + 1) % WAVEFORM_SAMPLES
			_gen_frames += 1

	queue_redraw()


func _start_sfx(type: String) -> void:
	_gen_type = type
	_gen_frames = 0
	_gen_phase = 0.0
	var durations := {"beep": 0.3, "buzz": 0.4, "crash": 0.2, "chirp": 0.5}
	_gen_total = int(durations.get(type, 0.3) * MIX_RATE)


func _get_sample(t: float) -> float:
	match _gen_type:
		"beep":
			var freq := 440.0
			_gen_phase += freq / MIX_RATE
			return sin(TAU * _gen_phase) * (1.0 - t)
		"buzz":
			var freq := 120.0
			_gen_phase += freq / MIX_RATE
			return sign(sin(TAU * _gen_phase)) * (1.0 - t)
		"crash":
			return (randf() * 2.0 - 1.0) * pow(1.0 - t, 0.5)
		"chirp":
			var freq := lerpf(200.0, 800.0, t)
			_gen_phase += freq / MIX_RATE
			return sin(TAU * _gen_phase) * (1.0 - pow(t, 2.0))
	return 0.0


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.06, 0.06, 0.10))

	# Separator
	draw_line(Vector2(0, 36), Vector2(640, 36), Color(0.3, 0.3, 0.4), 1)

	# Active SFX display
	var sfx_colors := {
		"beep": Color(0.3, 0.8, 0.4),
		"buzz": Color(0.9, 0.7, 0.1),
		"crash": Color(0.9, 0.3, 0.2),
		"chirp": Color(0.4, 0.7, 1.0),
	}
	var active_color: Color = sfx_colors.get(_gen_type, Color(0.4, 0.4, 0.4)) if _gen_frames < _gen_total else Color(0.3, 0.3, 0.3)

	draw_rect(Rect2(20, 55, 600, 36), active_color * Color(1, 1, 1, 0.15))
	draw_rect(Rect2(20, 55, 600, 36), active_color * Color(1, 1, 1, 0.6), false, 2.0)

	var status := "Playing: %s" % _gen_type.to_upper() if (_gen_type != "" and _gen_frames < _gen_total) else "Idle — press 1-4"
	draw_string(ThemeDB.fallback_font, Vector2(30, 80), status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, active_color)

	# Progress bar for current SFX
	if _gen_type != "" and _gen_total > 0:
		var prog := clampf(float(_gen_frames) / float(_gen_total), 0.0, 1.0)
		draw_rect(Rect2(20, 98, 600, 8), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(20, 98, prog * 600.0, 8), active_color * Color(1, 1, 1, 0.7))

	# Waveform visualization
	draw_rect(Rect2(20, 120, 600, 140), Color(0.08, 0.1, 0.14))
	draw_rect(Rect2(20, 120, 600, 140), Color(0.25, 0.25, 0.35), false, 1.0)
	# Center line
	draw_line(Vector2(20, 190), Vector2(620, 190), Color(0.2, 0.2, 0.3), 1)
	draw_string(ThemeDB.fallback_font, Vector2(24, 134), "Waveform",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))

	# Draw waveform from ring buffer
	var prev := Vector2.ZERO
	for px in 600:
		var idx := (_wave_head + int(float(px) / 600.0 * WAVEFORM_SAMPLES)) % WAVEFORM_SAMPLES
		var sample := float(_wave_buf[idx])
		var y := 190.0 - sample * 60.0
		var cur := Vector2(20.0 + px, y)
		if px > 0:
			draw_line(prev, cur, active_color * Color(1, 1, 1, 0.85), 1.5)
		prev = cur

	# SFX key buttons
	var sfx_defs := [
		{"key": "1", "name": "Beep", "desc": "440 Hz sine\nfade out", "color": sfx_colors["beep"]},
		{"key": "2", "name": "Buzz", "desc": "120 Hz square\nwave fade", "color": sfx_colors["buzz"]},
		{"key": "3", "name": "Crash", "desc": "Noise burst\ndecaying", "color": sfx_colors["crash"]},
		{"key": "4", "name": "Chirp", "desc": "200→800 Hz\nascending", "color": sfx_colors["chirp"]},
	]
	for i in 4:
		var d: Dictionary = sfx_defs[i]
		var bx := 20.0 + i * 152.0
		var by := 285.0
		var is_active: bool = (_gen_type == ["beep", "buzz", "crash", "chirp"][i] and _gen_frames < _gen_total)
		var bg_alpha := 0.35 if is_active else 0.12
		draw_rect(Rect2(bx, by, 140, 80), d["color"] * Color(1, 1, 1, bg_alpha))
		draw_rect(Rect2(bx, by, 140, 80), d["color"] * Color(1, 1, 1, 0.7 if is_active else 0.4), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + 22), "[%s]  %s" % [d["key"], d["name"]],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, d["color"])
		draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + 44), (d["desc"] as String).split("\n")[0],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + 60), (d["desc"] as String).split("\n")[1],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))

	# Waveform type mini-previews
	_draw_mini_wave(Vector2(20, 390), "beep", sfx_colors["beep"])
	_draw_mini_wave(Vector2(180, 390), "buzz", sfx_colors["buzz"])
	_draw_mini_wave(Vector2(340, 390), "crash", sfx_colors["crash"])
	_draw_mini_wave(Vector2(500, 390), "chirp", sfx_colors["chirp"])


func _draw_mini_wave(pos: Vector2, type: String, color: Color) -> void:
	var w := 120.0
	var h := 40.0
	draw_rect(Rect2(pos.x, pos.y, w, h), Color(0.1, 0.1, 0.15))
	var prev := Vector2.ZERO
	for px in int(w):
		var t := float(px) / w
		var y := 0.0
		match type:
			"beep":
				y = sin(TAU * t * 3.0) * (1.0 - t)
			"buzz":
				y = sign(sin(TAU * t * 3.0)) * (1.0 - t) * 0.8
			"crash":
				# Deterministic noise-like: use a pseudo pattern
				y = sin(TAU * t * 17.3 + 0.7) * pow(1.0 - t, 0.5) * 0.9
			"chirp":
				var freq_t := lerpf(1.0, 5.0, t)
				y = sin(TAU * t * freq_t) * (1.0 - pow(t, 2.0))
		var cur := Vector2(pos.x + px, pos.y + h * 0.5 - y * h * 0.45)
		if px > 0:
			draw_line(prev, cur, color * Color(1, 1, 1, 0.8), 1.0)
		prev = cur
