extends Control

enum Mode { NONE, DISSOLVE, PIXELATE, WAVE }

var _mode     := Mode.NONE
var _dissolve := 0.0
var _dissolve_dir := 1

@onready var _sprite:     Sprite2D = $SpriteAnchor/Sprite2D
@onready var _mode_label: Label    = $ModeLabel

const SHADERS := {
	Mode.NONE:     "",
	Mode.DISSOLVE: "res://shaders/dissolve.gdshader",
	Mode.PIXELATE: "res://shaders/pixelate.gdshader",
	Mode.WAVE:     "res://shaders/wave_distort.gdshader",
}

func _ready() -> void:
	$Buttons/NoneBtn.pressed.connect(func() -> void:     _set_mode(Mode.NONE))
	$Buttons/DissolveBtn.pressed.connect(func() -> void: _set_mode(Mode.DISSOLVE))
	$Buttons/PixelBtn.pressed.connect(func() -> void:    _set_mode(Mode.PIXELATE))
	$Buttons/WaveBtn.pressed.connect(func() -> void:     _set_mode(Mode.WAVE))
	_set_mode(Mode.NONE)

func _process(delta: float) -> void:
	if _mode == Mode.DISSOLVE and _sprite.material is ShaderMaterial:
		_dissolve += delta * _dissolve_dir * 0.6
		if _dissolve >= 1.0:
			_dissolve = 1.0
			_dissolve_dir = -1
		elif _dissolve <= 0.0:
			_dissolve = 0.0
			_dissolve_dir = 1
		(_sprite.material as ShaderMaterial).set_shader_parameter("dissolve_amount", _dissolve)

	if _mode == Mode.PIXELATE and _sprite.material is ShaderMaterial:
		var t := (sin(Time.get_ticks_msec() / 1000.0) + 1.0) * 0.5
		var px := lerpf(1.0, 16.0, t)
		(_sprite.material as ShaderMaterial).set_shader_parameter("pixel_size", px)

func _set_mode(m: Mode) -> void:
	_mode     = m
	_dissolve = 0.0
	_dissolve_dir = 1
	var path := SHADERS[m]
	if path.is_empty():
		_sprite.material = null
		_mode_label.text = "No shader — raw sprite"
	else:
		var mat := ShaderMaterial.new()
		mat.shader = load(path)
		_sprite.material = mat
		_mode_label.text = path.get_file().get_basename()
