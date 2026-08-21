extends Node2D

const MIX_RATE := 44100.0

@onready var _calm_player: AudioStreamPlayer = $CalmPlayer
@onready var _combat_player: AudioStreamPlayer = $CombatPlayer

var _calm_phase := 0.0
var _combat_phase1 := 0.0
var _combat_phase2 := 0.0
var _state := "calm"  # "calm" or "combat"


func _ready() -> void:
	# Set up calm stream: 220 Hz sine
	var cs := AudioStreamGenerator.new()
	cs.mix_rate = MIX_RATE
	cs.buffer_length = 0.1
	_calm_player.stream = cs
	_calm_player.play()
	_calm_player.volume_db = 0.0

	# Set up combat stream: 440 Hz + 330 Hz mix
	var bs := AudioStreamGenerator.new()
	bs.mix_rate = MIX_RATE
	bs.buffer_length = 0.1
	_combat_player.stream = bs
	_combat_player.play()
	_combat_player.volume_db = -80.0


## Whether switching to `target` would change anything. Pressing C while already
## calm must not restart the crossfade, or holding the key would keep the volume
## pinned at the start of a fade that never finishes.
func wants(target: String) -> bool:
	return _state != target

## One sample of the calm layer: a single 220 Hz tone.
func calm_sample(phase: float) -> float:
	return sin(TAU * phase) * 0.4

## One sample of the combat layer: two tones a fifth apart, summed. Half the
## amplitude each, so the pair peaks at the same level as the calm layer's one.
func combat_sample(phase1: float, phase2: float) -> float:
	return sin(TAU * phase1) * 0.25 + sin(TAU * phase2) * 0.25

## Advance a phase by one sample at `freq`, wrapping at a whole cycle.
func advance_phase(phase: float, freq: float) -> float:
	return fmod(phase + freq / MIX_RATE, 1.0)

func _process(_delta: float) -> void:
	# --- Input ---
	if Input.is_key_pressed(KEY_C) and wants("calm"):
		_transition("calm")
	if Input.is_key_pressed(KEY_F) and wants("combat"):
		_transition("combat")

	# --- Fill calm buffer (220 Hz sine) ---
	var calm_pb := _calm_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if calm_pb:
		var n := calm_pb.get_frames_available()
		for i in n:
			var s := calm_sample(_calm_phase)
			calm_pb.push_frame(Vector2(s, s))
			_calm_phase = advance_phase(_calm_phase, 220.0)

	# --- Fill combat buffer (440 Hz + 330 Hz mix) ---
	var combat_pb := _combat_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if combat_pb:
		var n := combat_pb.get_frames_available()
		for i in n:
			var s := combat_sample(_combat_phase1, _combat_phase2)
			combat_pb.push_frame(Vector2(s, s))
			_combat_phase1 = advance_phase(_combat_phase1, 440.0)
			_combat_phase2 = advance_phase(_combat_phase2, 330.0)

	queue_redraw()


func _transition(new_state: String) -> void:
	_state = new_state
	var tw := create_tween()
	if new_state == "calm":
		tw.tween_property(_calm_player, "volume_db", 0.0, 1.0)
		tw.parallel().tween_property(_combat_player, "volume_db", -80.0, 1.0)
	else:
		tw.tween_property(_combat_player, "volume_db", 0.0, 1.0)
		tw.parallel().tween_property(_calm_player, "volume_db", -80.0, 1.0)


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.08, 0.12))

	# Title area separator
	draw_line(Vector2(0, 36), Vector2(640, 36), Color(0.3, 0.3, 0.4), 1)

	# State indicator bar
	var bar_color := Color(0.2, 0.5, 0.9) if _state == "calm" else Color(0.9, 0.2, 0.2)
	draw_rect(Rect2(20, 80, 600, 40), bar_color * Color(1, 1, 1, 0.2))
	draw_rect(Rect2(20, 80, 600, 40), bar_color, false, 2.0)

	# State text drawn via the label node; draw a colored glow band beneath
	var state_text := "STATE: CALM  (220 Hz sine)" if _state == "calm" else "STATE: COMBAT  (440 Hz + 330 Hz)"
	draw_string(ThemeDB.fallback_font, Vector2(30, 108), state_text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 18, bar_color)

	# Volume meters
	_draw_meter(Vector2(40, 160), "Calm Layer", _calm_player.volume_db, Color(0.2, 0.6, 1.0))
	_draw_meter(Vector2(40, 220), "Combat Layer", _combat_player.volume_db, Color(1.0, 0.35, 0.2))

	# Waveform hint icons
	_draw_calm_wave(Vector2(40, 290))
	_draw_combat_wave(Vector2(40, 360))

	# Key hints at bottom
	draw_string(ThemeDB.fallback_font, Vector2(20, 470),
			"Press C = Calm   Press F = Fight/Combat   (1-second crossfade)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))


func _draw_meter(pos: Vector2, label: String, vol_db: float, color: Color) -> void:
	var label_w := 140
	# Background track
	draw_rect(Rect2(pos.x + label_w, pos.y, 420, 22), Color(0.15, 0.15, 0.2))
	# Fill: map -80..0 dB to 0..420 px
	var frac := clampf((vol_db + 80.0) / 80.0, 0.0, 1.0)
	draw_rect(Rect2(pos.x + label_w, pos.y, frac * 420.0, 22), color * Color(1, 1, 1, 0.8))
	# Border
	draw_rect(Rect2(pos.x + label_w, pos.y, 420, 22), Color(0.5, 0.5, 0.6), false, 1.0)
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(pos.x, pos.y + 16), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.9))
	# dB value
	var db_str := "%.1f dB" % vol_db
	draw_string(ThemeDB.fallback_font, Vector2(pos.x + label_w + 426, pos.y + 16), db_str,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.7, 0.7))


func _draw_calm_wave(pos: Vector2) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, 14), "Calm (220 Hz):",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.7, 1.0))
	var prev := Vector2.ZERO
	for px in 200:
		var phase := float(px) / 200.0 * 4.0  # show 4 cycles
		var y := sin(TAU * phase) * 18.0
		var cur := Vector2(pos.x + 150 + px, pos.y + y)
		if px > 0:
			draw_line(prev, cur, Color(0.3, 0.6, 1.0), 1.5)
		prev = cur


func _draw_combat_wave(pos: Vector2) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, 14), "Combat (440+330 Hz):",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.4, 0.3))
	var prev := Vector2.ZERO
	for px in 200:
		var phase1 := float(px) / 200.0 * 8.0
		var phase2 := float(px) / 200.0 * 6.0
		var y := (sin(TAU * phase1) * 0.5 + sin(TAU * phase2) * 0.5) * 18.0
		var cur := Vector2(pos.x + 150 + px, pos.y + y)
		if px > 0:
			draw_line(prev, cur, Color(1.0, 0.4, 0.3), 1.5)
		prev = cur
