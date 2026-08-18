extends Node2D

const SAMPLE_RATE := 44100
const BUSES := ["Dry", "Reverb", "Echo", "Compressed"]

var _current_bus := 0
var _player:      AudioStreamPlayer

@onready var _bus_label:  Label = $CanvasLayer/BusLabel
@onready var _info_label: Label = $CanvasLayer/InfoLabel

func _ready() -> void:
	_setup_buses()
	_player = $AudioStreamPlayer
	_player.stream = _make_tone(440.0, 0.6)
	_player.bus     = BUSES[_current_bus]
	_update_label()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		_current_bus = (_current_bus + 1) % BUSES.size()
		_player.bus  = BUSES[_current_bus]
		_update_label()
	elif event.is_action_pressed("ui_left"):
		_current_bus = (_current_bus - 1 + BUSES.size()) % BUSES.size()
		_player.bus  = BUSES[_current_bus]
		_update_label()
	elif event.is_action_pressed("ui_select"):
		_player.play()

func _setup_buses() -> void:
	# Dry bus: deliberately empty, and the reference the others are heard
	# against. It has to exist like the rest — assigning a player to a bus that
	# was never created is silently ignored, and the player stays on Master
	# while the label claims otherwise.
	if AudioServer.get_bus_index("Dry") == -1:
		AudioServer.add_bus()
		var dry_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(dry_idx, "Dry")
		AudioServer.set_bus_send(dry_idx, "Master")

	# Reverb bus
	if AudioServer.get_bus_index("Reverb") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Reverb")
		AudioServer.set_bus_send(idx, "Master")
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.85
		rev.wet = 0.65
		rev.dry = 0.6
		AudioServer.add_bus_effect(idx, rev)

	# Echo bus
	if AudioServer.get_bus_index("Echo") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Echo")
		AudioServer.set_bus_send(idx, "Master")
		var delay := AudioEffectDelay.new()
		delay.tap1_active    = true
		delay.tap1_delay_ms  = 300.0
		delay.tap1_level_db  = -6.0
		delay.tap2_active    = true
		delay.tap2_delay_ms  = 600.0
		delay.tap2_level_db  = -12.0
		AudioServer.add_bus_effect(idx, delay)

	# Compressed bus
	if AudioServer.get_bus_index("Compressed") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Compressed")
		AudioServer.set_bus_send(idx, "Master")
		var comp := AudioEffectCompressor.new()
		comp.threshold = -24.0
		comp.ratio = 6.0
		comp.attack_us = 20.0
		comp.release_ms = 250.0
		AudioServer.add_bus_effect(idx, comp)

func _update_label() -> void:
	_bus_label.text = "Bus: %s  (Left/Right to switch, Space to play)" % BUSES[_current_bus]
	var desc := {
		"Dry":        "Direct signal — no effects",
		"Reverb":     "Room reverb: large space simulation via dense reflections",
		"Echo":       "Delay: tap1 at 300ms, tap2 at 600ms, each 6dB quieter",
		"Compressed": "Compressor: threshold −24dB, ratio 6:1 — evens out dynamics",
	}
	_info_label.text = desc.get(BUSES[_current_bus], "")

func _make_tone(freq: float, duration: float) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data    := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t   := float(i) / SAMPLE_RATE
		var raw := sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.2
		var env := 1.0 - pow(float(i) / samples, 0.5)
		var s   := clampi(int(raw * 22000.0 * env), -32768, 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data     = data
	return wav
