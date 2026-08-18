extends Node2D

const SAMPLE_RATE := 22050
const LISTENER_SPEED := 200.0

@onready var source   : Node2D             = $SoundSource
@onready var player   : AudioStreamPlayer2D = $SoundSource/Player
@onready var listener : Node2D             = $Listener
@onready var info     : Label              = $InfoLabel

func _ready() -> void:
	player.stream = _make_tone(440.0, 2.0)
	player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream.loop_begin = 0
	player.stream.loop_end = SAMPLE_RATE * 2
	player.play()
	# Register listener position with AudioServer
	AudioServer.set_playback_speed_scale(1.0)

func _make_tone(freq: float, duration: float) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data    := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t   := float(i) / SAMPLE_RATE
		var raw := int(sin(TAU * freq * t) * 28000)
		raw = clampi(raw, -32768, 32767)
		data[i * 2]     = raw & 0xFF
		data[i * 2 + 1] = (raw >> 8) & 0xFF
	var wav          := AudioStreamWAV.new()
	wav.data          = data
	wav.format        = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate      = SAMPLE_RATE
	return wav

func _physics_process(delta: float) -> void:
	tick(delta, Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	queue_redraw()

## How loud the source is from a given distance, as a fraction.
##
## AudioStreamPlayer2D uses the nearest AudioListener2D in the scene tree; this
## works the same falloff out by hand so the number can be shown on screen.
func volume_at(dist: float) -> float:
	var vol := clampf(1.0 - dist / player.max_distance, 0.0, 1.0)
	return pow(vol, player.attenuation)

func tick(delta: float, dir: Vector2) -> void:
	listener.position += dir * LISTENER_SPEED * delta
	listener.position  = listener.position.clamp(Vector2(20, 60), Vector2(620, 460))

	var dist := listener.position.distance_to(source.position)
	var vol  := volume_at(dist)
	info.text = "Distance: %.0f px   Volume: %.0f%%   Max dist: %.0f px" % [
		dist, vol * 100, player.max_distance]

func _draw() -> void:
	# Max-distance circle
	draw_arc(source.position, player.max_distance, 0, TAU, 64,
		Color(1, 1, 1, 0.15), 1)
	# Distance rings
	for r in [100, 200, 300]:
		draw_arc(source.position, r, 0, TAU, 48, Color(1, 1, 1, 0.06), 1)
	# Source
	draw_circle(source.position, 20, Color.GOLD)
	draw_string(ThemeDB.fallback_font, source.position + Vector2(-16, -28),
		"SOURCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GOLD)
	# Listener
	draw_circle(listener.position, 14, Color.CORNFLOWER_BLUE)
	# Draw a simple ear shape indicator
	draw_arc(listener.position, 14, -PI * 0.4, PI * 0.4, 16, Color.WHITE, 3)
	draw_string(ThemeDB.fallback_font, listener.position + Vector2(-18, -26),
		"EAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.CORNFLOWER_BLUE)
	# Line between them
	draw_line(source.position, listener.position, Color(1, 1, 1, 0.3), 1)
