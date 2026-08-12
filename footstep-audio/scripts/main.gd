extends Node2D

const SAMPLE_RATE := 22050

const SURFACE_CONFIG := {
	"stone":  {"freq": 380.0, "dur": 0.05, "wave": "square", "label": "Stone",  "color": Color(0.6, 0.6, 0.65)},
	"grass":  {"freq": 160.0, "dur": 0.10, "wave": "sweep",  "label": "Grass",  "color": Color(0.2, 0.65, 0.2)},
	"wood":   {"freq": 260.0, "dur": 0.07, "wave": "sine",   "label": "Wood",   "color": Color(0.7, 0.45, 0.2)},
	"water":  {"freq": 200.0, "dur": 0.12, "wave": "sine",   "label": "Water",  "color": Color(0.2, 0.5, 0.9)},
	"metal":  {"freq": 600.0, "dur": 0.04, "wave": "square", "label": "Metal",  "color": Color(0.6, 0.65, 0.75)},
}

var _last_step_label := ""

@onready var _player:      CharacterBody2D  = $Player
@onready var _audio:       AudioStreamPlayer = $AudioPlayer
@onready var _step_label:  Label             = $HUD/StepLabel
@onready var _surf_label:  Label             = $HUD/SurfLabel

func _ready() -> void:
	_player.stepped.connect(_on_step)

	for zone in $SurfaceZones.get_children():
		var surface_name: String = zone.surface_name
		zone.body_entered.connect(func(b: Node2D) -> void:
			if b == _player:
				_player.set_surface(surface_name)
				_surf_label.text = "Surface: " + SURFACE_CONFIG[surface_name]["label"]
		)
		zone.body_exited.connect(func(b: Node2D) -> void:
			if b == _player:
				_player.set_surface("stone")
				_surf_label.text = "Surface: Stone (default)"
		)

	_surf_label.text = "Surface: Stone (default)"

func _on_step(surface: String) -> void:
	var cfg: Dictionary = SURFACE_CONFIG.get(surface, SURFACE_CONFIG["stone"])
	_audio.stream = _make_tone(cfg["freq"], cfg["dur"], cfg["wave"])
	_audio.play()
	_step_label.text = "Last step: %s [%s %.0fHz]" % [cfg["label"], cfg["wave"], cfg["freq"]]

func _make_tone(freq: float, duration: float, wave: String) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data    := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t        := float(i) / SAMPLE_RATE
		var envelope := 1.0 - pow(float(i) / samples, 0.4)
		var raw: float
		match wave:
			"sine":
				raw = sin(TAU * freq * t)
			"square":
				raw = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			"sweep":
				raw = sin(TAU * lerpf(freq * 0.6, freq * 1.6, float(i) / samples) * t)
		var sample := clampi(int(raw * 24000.0 * envelope), -32768, 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav         := AudioStreamWAV.new()
	wav.data        = data
	wav.format      = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate    = SAMPLE_RATE
	return wav

func _draw() -> void:
	# Ground
	draw_rect(Rect2(0, 430, 640, 50), Color(0.5, 0.5, 0.5))
	# Surface zones (visual)
	var zones := $SurfaceZones.get_children()
	for zone in zones:
		var area := zone as Area2D
		if not area:
			continue
		var cfg: Dictionary = SURFACE_CONFIG.get(zone.surface_name, {})
		if cfg.is_empty():
			continue
		var col: Color = cfg["color"]
		var sh := area.get_child(0) as CollisionShape2D
		if sh and sh.shape is RectangleShape2D:
			var sz: Vector2 = (sh.shape as RectangleShape2D).size
			var pos := area.global_position - sz * 0.5
			draw_rect(Rect2(pos, sz), col.darkened(0.2))
			draw_rect(Rect2(pos, sz), col, false, 2.0)
			draw_string(ThemeDB.fallback_font, pos + Vector2(4, sz.y - 4), cfg["label"],
				HORIZONTAL_ALIGNMENT_LEFT, sz.x - 8, 12)
