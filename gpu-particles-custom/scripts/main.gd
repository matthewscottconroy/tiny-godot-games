extends Node2D

const PRESETS := ["Curl Noise", "Radial Orbit", "Swarm"]

var _preset := 0
var _time := 0.0

@onready var _rect: ColorRect = $Surface
@onready var _label: Label = $Label

func _ready() -> void:
	_update_label()

func _process(delta: float) -> void:
	_time += delta
	var mat: ShaderMaterial = _rect.material
	mat.set_shader_parameter("time_val", _time)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_preset = (_preset + 1) % PRESETS.size()
				_rect.material.set_shader_parameter("preset", _preset)
				_time = 0.0
				_update_label()

func _update_label() -> void:
	_label.text = "Space — cycle preset\nPreset: %s" % PRESETS[_preset]
