extends Control

enum ShaderMode { NONE, TINT, FLASH, OUTLINE }

var mode := ShaderMode.NONE

@onready var sprite: Sprite2D = $SpriteAnchor/Sprite2D
@onready var mode_label: Label = $ModeLabel

const SHADERS := {
	ShaderMode.NONE:    "",
	ShaderMode.TINT:    "res://shaders/tint.gdshader",
	ShaderMode.FLASH:   "res://shaders/flash.gdshader",
	ShaderMode.OUTLINE: "res://shaders/outline.gdshader",
}

func _ready() -> void:
	$Buttons/NoneBtn.pressed.connect(func(): _set_mode(ShaderMode.NONE))
	$Buttons/TintBtn.pressed.connect(func(): _set_mode(ShaderMode.TINT))
	$Buttons/FlashBtn.pressed.connect(func(): _set_mode(ShaderMode.FLASH); _trigger_flash())
	$Buttons/OutlineBtn.pressed.connect(func(): _set_mode(ShaderMode.OUTLINE))
	_set_mode(ShaderMode.NONE)

func _set_mode(new_mode: ShaderMode) -> void:
	mode = new_mode
	var path: String = SHADERS[mode]
	if path.is_empty():
		sprite.material = null
		mode_label.text = "No shader — raw sprite"
	else:
		var mat := ShaderMaterial.new()
		mat.shader = load(path)
		sprite.material = mat
		mode_label.text = path.get_file()

func _trigger_flash() -> void:
	if not sprite.material is ShaderMaterial:
		return
	var mat := sprite.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(v: float): mat.set_shader_parameter("flash_amount", v), 1.0, 0.0, 0.4)
