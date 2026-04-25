extends Control

# Tones are generated programmatically — no audio files needed.
# This demonstrates AudioStreamWAV, AudioStreamPlayer, and bus routing.

const SAMPLE_RATE := 22050

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var vol_slider: HSlider = $VolumeRow/VolumeSlider
@onready var bus_label: Label = $BusLabel

func _ready() -> void:
	_setup_buses()
	sfx_player.bus = "SFX"
	vol_slider.value = 0.0
	vol_slider.value_changed.connect(_on_volume_changed)
	$ButtonRow/LowBtn.pressed.connect(_on_low_pressed)
	$ButtonRow/MidBtn.pressed.connect(_on_mid_pressed)
	$ButtonRow/HighBtn.pressed.connect(_on_high_pressed)
	$ButtonRow/SquareBtn.pressed.connect(_on_square_pressed)
	$ButtonRow/SweepBtn.pressed.connect(_on_sweep_pressed)
	_update_bus_label()

func _setup_buses() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")

func _make_tone(freq: float, duration: float, wave: String = "sine") -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0 - pow(float(i) / samples, 0.5)
		var raw: float
		match wave:
			"sine":   raw = sin(TAU * freq * t)
			"square": raw = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			"sweep":  raw = sin(TAU * lerpf(freq * 0.5, freq * 2.0, float(i) / samples) * t)
		var sample := int(raw * 28000 * envelope)
		sample = clampi(sample, -32768, 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	return wav

func _play(freq: float, duration: float, wave: String = "sine") -> void:
	sfx_player.stream = _make_tone(freq, duration, wave)
	sfx_player.play()

func _on_low_pressed()    -> void: _play(180, 0.4)
func _on_mid_pressed()    -> void: _play(440, 0.3)
func _on_high_pressed()   -> void: _play(880, 0.25)
func _on_square_pressed() -> void: _play(220, 0.4, "square")
func _on_sweep_pressed()  -> void: _play(300, 0.5, "sweep")

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
	_update_bus_label()

func _update_bus_label() -> void:
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	bus_label.text = "SFX Bus volume: %.1f dB" % db
